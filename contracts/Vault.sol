// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBAToken.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IAaveLendingPool.sol";
import "./interfaces/QiTokenInterfaces.sol";
import "./interfaces/QiComptrollerInterface.sol";

import {DataTypes} from "./libraries/DataTypes.sol";

contract Vault is Ownable {
    address public collateralAsset;
    address public borrowAsset;

    uint256 decimalsAsset;
    uint8 factorA;
    uint8 factorB;
    uint8 factorFees;

    IBAToken baToken;
    IStrategy strategy;
    IOracle oracle;
    IAaveLendingPool aavePool;
    IQiToken qiAvax;
    IQiComptroller qiComptroller;

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
        address _baToken,
        address _aavePool,
        address _qiAvax,
        address _qiComptroller
    ) external onlyOwner {
        // Smart contracts
        oracle = IOracle(_oracle);
        strategy = IStrategy(_strategy);
        baToken = IBAToken(_baToken);
        aavePool = IAaveLendingPool(_aavePool);
        qiAvax = IQiToken(_qiAvax);
        qiComptroller = IQiComptroller(_qiComptroller);

        address[] memory qiTokens = new address[](1);
        qiTokens[0] = address(qiAvax);
        qiComptroller.enterMarkets(qiTokens);

        // Variables
        decimalsAsset = 18;
        factorA = 3;
        factorB = 4;
        factorFees = 5;
    }

    ////////////////////////////////
    //     EXTERNAL FUNCTIONS     //
    ////////////////////////////////

    function deposit(uint256 _amountToDeposit) external payable {
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

    function withdraw(uint256 _amountToWithdraw) external payable {
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

        uint256 amountToPay = _amountToWithdraw -
            feesFromWithdraw(_amountToWithdraw);
        IERC20(collateralAsset).transferFrom(
            address(this),
            msg.sender,
            amountToPay
        );

        emit Withdraw(collateralAsset, msg.sender, _amountToWithdraw);
    }

    function borrow(uint256 _amountToBorrow) external payable {
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

    function repay(uint256 _amountToRepay) external payable {
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

    function getHealthFactor() external view returns (uint256) {
        uint256 _collateral = getDebtCollateralToken();
        uint256 _borrow = getDebtBorrowToken();
        uint256 _healthFactor = healthFactor(_collateral, _borrow);

        return _healthFactor;
    }

    function getTVL() external view returns (uint256) {
        uint256 _collateral = getDebtCollateralToken();
        uint256 _borrow = getDebtBorrowToken();
        uint256 _tvl = TVL(_collateral, _borrow);

        return _tvl;
    }

    function getBorrowLimitUsed() external view returns (uint256) {
        uint256 _collateral = getDebtCollateralToken();
        uint256 _borrow = getDebtBorrowToken();
        uint256 _borrowLimitUsed = borrowLimitUsed(_collateral, _borrow);

        return _borrowLimitUsed;
    }

    function changeProtocol() external payable onlyOwner {
        if (strategy.getActiveStrategy() == 0) {
            uint256 _amount = baToken.getTotalSupply(ids[collateralAsset]);
            _lendFromProtocol(_amount, 1);
            uint256 amount_borrowed = baToken.getTotalSupply(ids[borrowAsset]);
            _borrowFromProtocol(amount_borrowed, 1);
            _repayProtocol(amount_borrowed, 0);
            _withdrawFromProtocol(_amount, 0);
        } else {
            uint256 _amount = baToken.getTotalSupply(ids[collateralAsset]);
            _lendFromProtocol(_amount, 0);
            uint256 amount_borrowed = baToken.getTotalSupply(ids[borrowAsset]);
            _borrowFromProtocol(amount_borrowed, 0);
            _repayProtocol(amount_borrowed, 1);
            _withdrawFromProtocol(_amount, 1);
        }
    }

    ////////////////////////////////
    //     PRIVATE FUNCTIONS      //
    ////////////////////////////////

    function _lendFromProtocol(uint256 _amount, int256 _strategy) private {
        // INTERFACE WITH AAVE/BENQI
        if (_strategy == 0) {
            IERC20(collateralAsset).approve(address(aavePool), _amount);
            aavePool.deposit(collateralAsset, _amount, msg.sender, 0);
            aavePool.setUserUseReserveAsCollateral(collateralAsset, true);
        } else {
            IERC20(collateralAsset).approve(address(qiAvax), _amount);
            qiAvax.mint(_amount);
        }
    }

    function _withdrawFromProtocol(uint256 _amount, int256 _strategy) private {
        // INTERFACE WITH AAVE/BENQI
        if (_strategy == 0) {
            IERC20(collateralAsset).approve(address(aavePool), _amount);
            aavePool.withdraw(collateralAsset, _amount, msg.sender);
        } else {
            IERC20(collateralAsset).approve(address(qiAvax), _amount);
            qiAvax.redeem(_amount);
        }
    }

    function _borrowFromProtocol(uint256 _amount, int256 _strategy) private {
        // INTERFACE WITH AAVE/BENQI
        if (_strategy == 0) {
            IERC20(borrowAsset).approve(address(aavePool), _amount);
            aavePool.borrow(collateralAsset, _amount, 2, 0, msg.sender);
        } else {
            IERC20(borrowAsset).approve(address(qiAvax), _amount);
            qiAvax.borrow(_amount);
        }
    }

    function _repayProtocol(uint256 _amount, int256 _strategy) private {
        // INTERFACE WITH AAVE/BENQI
        if (_strategy == 0) {
            IERC20(borrowAsset).approve(address(aavePool), _amount);
            aavePool.repay(borrowAsset, _amount, 2, msg.sender);
        } else {
            IERC20(borrowAsset).approve(address(aavePool), _amount);
            qiAvax.repayBorrow(_amount);
        }
    }

    function feesFromWithdraw(uint256 _amount) private view returns (uint256) {
        uint256 fees = (_amount * factorFees) / 1000;

        return fees;
    }

    function healthFactor(uint256 collateral, uint256 borrow)
        private
        view
        returns (uint256)
    {
        uint256 price = oracle.getPairPrice(collateralAsset, borrowAsset);
        uint256 _healthfactor = (price * collateral * factorA) /
            (borrow * factorB);

        return _healthfactor;
    }

    function TVL(uint256 collateral, uint256 borrow)
        private
        view
        returns (uint256)
    {
        uint256 price = oracle.getPairPrice(collateralAsset, borrowAsset);
        uint256 _tvl = (price * borrow) / collateral;

        return _tvl;
    }

    function borrowLimitUsed(uint256 collateral, uint256 borrow)
        private
        view
        returns (uint256)
    {
        uint256 price = oracle.getPairPrice(collateralAsset, borrowAsset);
        uint256 _borrowLimitUsed = (price * borrow * factorB) /
            (collateral * factorA);

        return _borrowLimitUsed;
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
