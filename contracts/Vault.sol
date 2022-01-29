// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBAToken.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IAaveLendingPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DataTypes} from "./libraries/DataTypes.sol";

contract Vault is Ownable {
    address public collateralAsset;
    address public borrowAsset;

    uint256 decimalsAsset;
    uint8 factorA;
    uint8 factorB;

    uint256 DECIMALS = 10**6; // to 0.get a 5 digits uint APR like : xxxxx means x,xxxx% APR

    IBAToken baToken;
    IStrategy strategy;
    IOracle oracle;
    IAaveLendingPool aavePool;

    event Borrow(
        address indexed asset,
        address indexed depositor,
        uint256 indexed amount
    );
    event Repay(
        address indexed asset,
        address indexed depositor,
        uint256 indexed amount
    );

    event Deposit(
        address indexed asset,
        address indexed depositor,
        uint256 indexed amount
    );

    event Withdraw(
        address indexed asset,
        address indexed depositor,
        uint256 indexed amount
    );

    mapping(address => uint256) public ids;

    constructor(address _collateralAsset, address _borrowAsset) public {
        collateralAsset = _collateralAsset; // FUJI WAVAX : 0xd00ae08403B9bbb9124bB305C09058E32C39A48c
        borrowAsset = _borrowAsset; // FUJI WETH : 0x9668f5f55f2712Dd2dfa316256609b516292D554

        // IERC1155 Fuji AVAX
        ids[collateralAsset] = 0;
        // IERC1155 Fuji WETH
        ids[borrowAsset] = 1;
    }

    receive() external payable {}

    function initialization(
        address _oracle,
        address _strategy,
        address _baToken
    ) external onlyOwner {
        // Smart contracts
        oracle = IOracle(_oracle);
        strategy = IStrategy(_strategy);
        baToken = IBAToken(_baToken);
        aavePool = IAaveLendingPool(0x76cc67FF2CC77821A70ED14321111Ce381C2594D);

        // Variables
        decimalsAsset = 18;
        factorA = 3;
        factorB = 4;
    }

    ////////////////////////////////
    //      PUBLIC FUNCTIONS      //
    ////////////////////////////////

    function deposit(uint256 _amountToDeposit) public payable {
        require(_amountToDeposit != 0, "Invalid amount : should differ from 0");
        require(
            msg.value == _amountToDeposit,
            "Invalid amount : msgvalue should be the deposit"
        );

        // Lend
        IERC20(collateralAsset).transferFrom(
            msg.sender,
            address(this),
            _amountToDeposit
        );
        baToken.mint(msg.sender, ids[collateralAsset], _amountToDeposit);

        // Active lend
        int256 activeStrategy = strategy.getActiveStrategy();
        //_lendFromProtocol(_amountToDeposit, activeStrategy);

        emit Deposit(collateralAsset, msg.sender, _amountToDeposit);
    }

    function withdraw(uint256 _amountToWithdraw) public payable {
        uint256 userBalance = baToken.balanceOf(
            msg.sender,
            ids[collateralAsset]
        );
        require(
            _amountToWithdraw != 0,
            "Invalid amount : should differ from 0"
        );
        require(
            _amountToWithdraw <= userBalance,
            "You dont have enough deposit"
        );

        // Loan check
        uint256 _borrow = baToken.balanceOf(msg.sender, ids[borrowAsset]);
        uint256 newCollateral = userBalance - _amountToWithdraw;
        uint256 minCollateral = getMinCollateralforBorrow(_borrow);
        require(newCollateral > minCollateral, "healthFactor should be >=1");

        // Withdraw collateral
        baToken.burn(msg.sender, ids[collateralAsset], _amountToWithdraw);
        IERC20(collateralAsset).transferFrom(
            address(this),
            msg.sender,
            _amountToWithdraw
        );

        emit Withdraw(collateralAsset, msg.sender, _amountToWithdraw);
    }

    function borrow(uint256 _amountToBorrow) public payable {
        require(_amountToBorrow != 0, "Invalid amount : should differ from 0");

        // Collateral check
        uint256 collateral = baToken.balanceOf(
            msg.sender,
            ids[collateralAsset]
        );
        uint256 _borrow = _amountToBorrow +
            baToken.balanceOf(msg.sender, ids[borrowAsset]);
        uint256 minCollateral = getMinCollateralforBorrow(_borrow);
        require(collateral > minCollateral, "healthFactor should be >=1");

        // Active borrow
        int256 activeStrategy = strategy.getActiveStrategy();
        _borrowFromProtocol(_amountToBorrow, activeStrategy);

        // Borrow
        IERC20(borrowAsset).transferFrom(
            address(this),
            payable(msg.sender),
            _amountToBorrow
        );
        baToken.mint(msg.sender, ids[borrowAsset], _amountToBorrow);

        emit Borrow(borrowAsset, msg.sender, _amountToBorrow);
    }

    function repay(uint256 _amountToRepay) public payable {
        require(_amountToRepay != 0, "Invalid amount : should differ from 0");

        uint256 totalBorrowUser = baToken.balanceOf(
            msg.sender,
            ids[borrowAsset]
        );
        require(totalBorrowUser >= _amountToRepay, "Invalid amount");

        // Active repay
        int256 activeStrategy = strategy.getActiveStrategy();
        _repayProtocol(_amountToRepay, activeStrategy);

        // repay loan
        IERC20(borrowAsset).transferFrom(
            address(this),
            msg.sender,
            _amountToRepay
        );
        baToken.burn(msg.sender, ids[borrowAsset], _amountToRepay);

        emit Repay(borrowAsset, msg.sender, _amountToRepay);
    }

    ////////////////////////////////
    //     EXTERNAL FUNCTIONS     //
    ////////////////////////////////

    function depositAndBorrow(uint256 _amount) external payable {
        deposit(_amount);
        borrow(_amount);
    }

    function withdrawAndRepay(uint256 _amount) external payable {
        withdraw(_amount);
        repay(_amount);
    }

    function getHealthFactor() external returns (uint256) {
        uint256 collateral = getDebtCollateralToken();
        uint256 borrow = getDebtBorrowToken();
        uint256 healthFactor = healthFactor(collateral, borrow);

        return healthFactor;
    }

    function getTVL() external returns (uint256) {
        uint256 collateral = getDebtCollateralToken();
        uint256 borrow = getDebtBorrowToken();
        uint256 tvl = TVL(collateral, borrow);

        return tvl;
    }

    function getBorrowLimitUsed() external returns (uint256) {
        uint256 collateral = getDebtCollateralToken();
        uint256 borrow = getDebtBorrowToken();
        uint256 borrowLimitUsed = borrowLimitUsed(collateral, borrow);

        return borrowLimitUsed;
    }

    ////////////////////////////////
    //     PRIVATE FUNCTIONS      //
    ////////////////////////////////

    function _lendFromProtocol(uint256 _amount, int256 _strategy) private {
        if (_strategy == 0) {
            IERC20(collateralAsset).approve(address(aavePool), _amount);
            aavePool.deposit(collateralAsset, _amount, address(this), 0);
            aavePool.setUserUseReserveAsCollateral(collateralAsset, true);
        }
    }

    function _borrowFromProtocol(uint256 _amount, int256 _strategy) private {
        if (_strategy == 0) {
            aavePool.borrow(borrowAsset, _amount, 2, 0, address(this));
        }
    }

    function _repayProtocol(uint256 _amount, int256 _strategy) private {
        if (_strategy == 0) {
            aavePool.repay(borrowAsset, _amount, 2, address(this));
        }
    }

    function healthFactor(uint256 collateral, uint256 borrow)
        private
        returns (uint256)
    {
        uint256 price = oracle.getPairPrice(collateralAsset, borrowAsset);
        uint256 healthfactor = (price * collateral * factorA) /
            (borrow * factorB);

        return healthfactor;
    }

    function TVL(uint256 collateral, uint256 borrow) private returns (uint256) {
        uint256 price = oracle.getPairPrice(collateralAsset, borrowAsset);
        uint256 tvl = (price * borrow) / collateral;

        return tvl;
    }

    function borrowLimitUsed(uint256 collateral, uint256 borrow)
        private
        returns (uint256)
    {
        uint256 price = oracle.getPairPrice(collateralAsset, borrowAsset);
        uint256 borrowLimitUsed = (price * borrow * factorB) /
            (collateral * factorA);

        return borrowLimitUsed;
    }

    ////////////////////////////////
    //       VIEW FUNCTIONS       //
    ////////////////////////////////

    function getMinCollateralforBorrow(uint256 _borrow)
        public
        view
        returns (uint256)
    {
        uint256 price = oracle.getPairPrice(collateralAsset, borrowAsset);
        uint256 minCollateral = (price * _borrow * factorB) / factorA;

        return minCollateral;
    }

    function getDebtCollateralToken() public view returns (uint256) {
        uint256 balanceCollateralBAToken = baToken.balanceOf(
            msg.sender,
            ids[collateralAsset]
        );

        return balanceCollateralBAToken;
    }

    function getDebtBorrowToken() public view returns (uint256) {
        uint256 balanceBorrowBAToken = baToken.balanceOf(
            msg.sender,
            ids[borrowAsset]
        );

        return balanceBorrowBAToken;
    }
}
