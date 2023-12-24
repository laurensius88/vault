// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/Vault.sol";

interface IVault {
    function balances(
        address user,
        address token
    ) external view returns (uint256);
}

contract VaultTest is Test {
    Vault vault;

    IERC20 private constant weth =
        IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 private constant wbtc =
        IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    IERC20 private constant usdt =
        IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

    address private mockUser1 = 0x1FEACcB479834998BD7750754062347A6FaD8F9F;
    address private mockUser2 = 0x1f1AA183f1C20cb97b60D7cA1BdcC325574bd232;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arbitrum"));
        vault = new Vault(address(this));

        // Whitelist the token in the vault
        vault.whitelistToken(address(weth), true);
        vault.whitelistToken(address(address(usdt)), true);

        // Provide some tokens to mockUser1 and mockUser2
        deal(address(weth), mockUser1, 100 ether);
        deal(address(wbtc), mockUser1, 100 ether);
        deal(address(address(usdt)), mockUser2, 1e6 * 1e6);
    }

    function testDeposit() public {
        vm.startPrank(mockUser1);
        uint256 amount = 10 ether;
        weth.approve(address(vault), amount);
        vault.deposit(address(weth), amount);
        vm.stopPrank();
        assertEq(
            IVault(address(vault)).balances(mockUser1, address(weth)),
            amount
        );
    }

    function testWithdraw() public {
        vm.startPrank(mockUser2);
        uint256 amount = 1e4 * 1e6;
        IERC20(address(usdt)).approve(address(vault), amount);
        vault.deposit(address(usdt), amount);
        vault.withdraw(address(usdt), amount);
        vm.stopPrank();
        assertEq(IVault(address(vault)).balances(mockUser2, address(usdt)), 0);
    }

    function testPauseAndUnpauseOwner() public {
        vault.pause();

        vm.startPrank(mockUser1);
        uint256 amount = 10 ether;
        weth.approve(address(vault), amount);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        vault.deposit(address(weth), amount);
        vm.stopPrank();

        vault.unpause();

        vm.startPrank(mockUser1);
        weth.approve(address(vault), amount);
        vault.deposit(address(weth), amount);
        assertEq(
            IVault(address(vault)).balances(mockUser1, address(weth)),
            amount
        );
        vm.stopPrank();
    }

    function testPauseDepositWithdrawFailed() public {
        vault.pause();

        vm.startPrank(mockUser1);
        uint256 amount = 10 ether;
        weth.approve(address(vault), amount);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        vault.deposit(address(weth), amount);
        vm.stopPrank();

        vault.unpause();

        vm.startPrank(mockUser1);
        weth.approve(address(vault), amount);
        vault.deposit(address(weth), amount);
        assertEq(
            IVault(address(vault)).balances(mockUser1, address(weth)),
            amount
        );
        vm.stopPrank();

        vault.pause();

        vm.startPrank(mockUser1);
        weth.approve(address(vault), amount);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        vault.withdraw(address(weth), amount);
        vm.stopPrank();

        vault.unpause();

        vm.startPrank(mockUser1);
        weth.approve(address(vault), amount);

        vault.withdraw(address(weth), amount);
        assertEq(IVault(address(vault)).balances(mockUser1, address(weth)), 0);
        vm.stopPrank();
    }

    function testPauseAndUnpauseNonOwner() public {
        vm.startPrank(mockUser1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                mockUser1
            )
        );
        vault.pause();
        vm.stopPrank();
    }

    function testTokenNotWhitelist() public {
        vm.startPrank(mockUser1);
        uint256 amount = 10 ether;
        wbtc.approve(address(vault), amount);
        vm.expectRevert(abi.encodeWithSignature("TokenNotWhitelisted()"));
        vault.deposit(address(wbtc), amount);
        vm.stopPrank();
    }

    function testNotEnoughBalance() public {
        vm.startPrank(mockUser1);
        uint256 amount = 10 ether;
        weth.approve(address(vault), amount);
        vault.deposit(address(weth), amount);
        assertEq(
            IVault(address(vault)).balances(mockUser1, address(weth)),
            amount
        );
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        vault.withdraw(address(weth), amount + amount);
        vm.stopPrank();
    }

    function testWhitelistTokenByNonOwner() public {
        vm.startPrank(mockUser1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                mockUser1
            )
        );
        vault.whitelistToken(address(weth), true);
        vm.stopPrank();
    }

    function testSuccessfulWhitelist() public {
        vault.whitelistToken(address(wbtc), true);
        assertTrue(vault.whitelistedTokens(address(wbtc)));
    }

    function testWithdrawAfterTokenNotWhitelisted() public {
        vm.startPrank(mockUser1);
        uint256 amount = 10 ether;
        IERC20(address(weth)).approve(address(vault), amount);
        vault.deposit(address(weth), amount);
        vm.stopPrank();

        vault.whitelistToken(address(weth), false);

        vm.startPrank(mockUser1);
        vault.withdraw(address(weth), amount);
        vm.stopPrank();
        assertEq(IVault(address(vault)).balances(mockUser1, address(weth)), 0);
    }

    function testPartialWithdrawal() public {
        uint256 depositAmount = 100 ether;
        uint256 withdrawAmount = 50 ether;
        vm.startPrank(mockUser1);
        weth.approve(address(vault), depositAmount);
        vault.deposit(address(weth), depositAmount);

        vault.withdraw(address(weth), withdrawAmount);
        vm.stopPrank();

        assertEq(
            IVault(address(vault)).balances(mockUser1, address(weth)),
            depositAmount - withdrawAmount
        );
    }

    function testZeroAmountDeposit() public {
        vm.startPrank(mockUser1);
        weth.approve(address(vault), 0);
        vm.expectRevert(abi.encodeWithSignature("AmountNotEnough()"));
        vault.deposit(address(weth), 0);
        vm.stopPrank();
    }
}
