// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../../libraries/SafeERC20.sol";

contract ERC20ReturnFalseMock {
    uint256 private _allowance;

    // IERC20's functions are not pure, but these mock implementations are: to prevent Solidity from issuing warnings,
    // we write to a dummy state variable.
    uint256 private _dummy;

    function balanceOf(address) external view returns (uint256) {
        require(_dummy == 0, "Dummy"); // Dummy read from a state variable so that the function is view
        return 0;
    }

    function transfer(address, uint256) public returns (bool) {
        _dummy = 0;
        return false;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public returns (bool) {
        _dummy = 0;
        return false;
    }

    function approve(address, uint256) public returns (bool) {
        _dummy = 0;
        return false;
    }

    function allowance(address, address) public view returns (uint256) {
        require(_dummy == 0, "Dummy"); // Dummy read from a state variable so that the function is view
        return 0;
    }
}

contract ERC20ReturnTrueMock {
    mapping(address => uint256) private _allowances;

    // IERC20's functions are not pure, but these mock implementations are: to prevent Solidity from issuing warnings,
    // we write to a dummy state variable.
    uint256 private _dummy;

    function transfer(address, uint256) public returns (bool) {
        _dummy = 0;
        return true;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public returns (bool) {
        _dummy = 0;
        return true;
    }

    function approve(address, uint256) public returns (bool) {
        _dummy = 0;
        return true;
    }

    function setAllowance(uint256 allowance_) public {
        _allowances[msg.sender] = allowance_;
    }

    function allowance(address owner, address) public view returns (uint256) {
        return _allowances[owner];
    }
}

contract Permit2ReturnTrueMock {
    // IPermit2's functions are not pure, but these mock implementations are: to prevent Solidity from issuing warnings,
    // we write to a dummy state variable.
    uint256 private _dummy;

    function transferFrom(
        address,
        address,
        uint160,
        address
    ) public {
        _dummy = 0;
    }
}

contract ERC20NoReturnMock {
    mapping(address => uint256) private _allowances;

    // IERC20's functions are not pure, but these mock implementations are: to prevent Solidity from issuing warnings,
    // we write to a dummy state variable.
    uint256 private _dummy;

    function transfer(address, uint256) public {
        _dummy = 0;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public {
        _dummy = 0;
    }

    function approve(address, uint256) public {
        _dummy = 0;
    }

    function setAllowance(uint256 allowance_) public {
        _allowances[msg.sender] = allowance_;
    }

    function allowance(address owner, address) public view returns (uint256) {
        return _allowances[owner];
    }
}

contract ERC20ThroughZeroApprove {
    error NonZeroToNonZeroApprove();

    mapping(address => mapping(address => uint256)) private _allowances;

    function approve(address to, uint256 amount) public {
        if (_allowances[msg.sender][to] != 0 && amount != 0) revert NonZeroToNonZeroApprove();
        _allowances[msg.sender][to] = amount;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
}

contract ERC20PermitNoRevertMock is
    ERC20("ERC20PermitNoRevertMock", "ERC20PermitNoRevertMock"),
    ERC20Permit("ERC20PermitNoRevertMock")
{
    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function permitThatMayRevert(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        super.permit(owner, spender, value, deadline, v, r, s);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line no-empty-blocks
        try this.permitThatMayRevert(owner, spender, value, deadline, v, r, s) {} catch {}
    }
}

contract SafeERC20Wrapper {
    using SafeERC20 for IERC20;

    IERC20 private _token;

    constructor(IERC20 token) {
        _token = token;
    }

    function balanceOf() public view returns (uint256) {
        return _token.safeBalanceOf(address(0));
    }

    function transfer() public {
        _token.safeTransfer(address(0), 0);
    }

    function transferFrom() public {
        _token.safeTransferFrom(address(0), address(0), 0);
    }

    function transferFromUniversal(bool permit2) public {
        _token.safeTransferFromUniversal(address(0), address(0), 0, permit2);
    }

    function approve(uint256 amount) public {
        _token.forceApprove(address(0), amount);
    }

    function increaseAllowance(uint256 amount) public {
        _token.safeIncreaseAllowance(address(0), amount);
    }

    function decreaseAllowance(uint256 amount) public {
        _token.safeDecreaseAllowance(address(0), amount);
    }

    function permit(
        address, /* owner */
        address, /* spender */
        uint256, /* value */
        uint256, /* deadline */
        uint8, /* v */
        bytes32, /* r */
        bytes32 /* s */
    ) external {
        _token.safePermit(msg.data[4:]);
    }

    function setAllowance(uint256 allowance_) public {
        ERC20ReturnTrueMock(address(_token)).setAllowance(allowance_);
    }

    function allowance() public view returns (uint256) {
        return _token.allowance(address(0), address(0));
    }
}

contract SafeWETHWrapper {
    using SafeERC20 for IWETH;

    IWETH private _token;

    constructor(IWETH token) {
        _token = token;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
    }

    function deposit() external payable {
        _token.safeDeposit(msg.value);
    }

    function withdraw(uint256 amount) external {
        _token.safeWithdraw(amount);
    }

    function withdrawTo(uint256 amount, address to) external {
        _token.safeWithdrawTo(amount, to);
    }
}

contract ERC20WithSafeBalance {
    using SafeERC20 for IERC20;

    IERC20 private immutable _token;

    constructor(IERC20 token) {
        _token = token;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _token.balanceOf(account);
    }

    function safeBalanceOf(address account) public view returns (uint256) {
        return _token.safeBalanceOf(account);
    }
}
