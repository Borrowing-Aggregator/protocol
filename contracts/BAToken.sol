// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BAToken is IERC1155, Ownable{

   // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) internal balances;

  // Mapping from token ID to totalSupply
  mapping(uint256 => uint256) internal totalSupply;

  //adress should not be null
  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    require(account != address(0));
    return balances[id][account];
  }

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view override returns (uint256[] memory) {
    require(accounts.length == ids.length);

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory) public virtual override {
    revert("Tokens are non transferrable");
  }

  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory) public virtual override {
    revert("Tokens are non transferrable");
  }

  function mint(address _account, uint256 _id, uint256 _amount) public onlyOwner {
    require(_account != address(0));
    _mint(_account, _id, _amount);
    address operator = _msgSender();
    emit TransferSingle(operator, address(0), _account, _id, _amount);
  }

  function burn(address _account, uint256 _id, uint256 _amount) public onlyOwner {
    require(_account != address(0));
    _burn(_account, _id, _amount);
    emit TransferSingle(_msgSender(), _account, address(0), _id, _amount);
  }

  function _mint(address _account, uint256 _id, uint256 _amount) internal {
    uint256 accountBalance = balances[_id][_account];
    uint256 assetTotalBalance = totalSupply[_id];
    uint256 amountScaled = _amount;
    balances[_id][_account] = accountBalance + amountScaled;
    totalSupply[_id] = assetTotalBalance + amountScaled;
  }

  function _burn(address _account, uint256 _id, uint256 _amount) internal {
    uint256 accountBalance = balances[_id][_account];
    uint256 assetTotalBalance = totalSupply[_id];
    uint256 amountScaled = _amount;
    require(amountScaled != 0 && accountBalance >= amountScaled);
    balances[_id][_account] = accountBalance - amountScaled;
    totalSupply[_id] = assetTotalBalance - amountScaled;
  }
}
