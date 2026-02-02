// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BufferFund} from "../src/core/BufferFund.sol";

contract BufferFundTest is Test {
    BufferFund public bufferFund;

    address public owner;
    address public user1;
    address public user2;

    event ETHReceived(address indexed from, uint256 amount);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        bufferFund = new BufferFund(owner);
    }

    function test_ReceiveETH() public {
        console.log("=== test_ReceiveETH ===");
        uint256 sendAmount = 1 ether;
        console.log("Send amount:", sendAmount);
        vm.deal(user1, sendAmount);

        vm.expectEmit(true, false, false, true);
        emit ETHReceived(user1, sendAmount);

        vm.prank(user1);
        (bool success, ) = address(bufferFund).call{value: sendAmount}("");

        console.log("Transfer success:", success);
        console.log("BufferFund balance:", address(bufferFund).balance);
        console.log("getBalance():", bufferFund.getBalance());

        assertTrue(success, "ETH transfer failed");
        assertEq(
            address(bufferFund).balance,
            sendAmount,
            "BufferFund balance incorrect"
        );
        assertEq(bufferFund.getBalance(), sendAmount, "getBalance() incorrect");
    }

    function test_ReceiveMultipleDeposits() public {
        console.log("=== test_ReceiveMultipleDeposits ===");
        uint256 amount1 = 1 ether;
        uint256 amount2 = 0.5 ether;
        console.log("Amount 1:", amount1);
        console.log("Amount 2:", amount2);

        vm.deal(user1, amount1);
        vm.deal(user2, amount2);

        vm.prank(user1);
        payable(address(bufferFund)).transfer(amount1);
        console.log("After deposit 1 - Balance:", bufferFund.getBalance());

        vm.prank(user2);
        payable(address(bufferFund)).transfer(amount2);
        console.log("After deposit 2 - Balance:", bufferFund.getBalance());

        assertEq(
            bufferFund.getBalance(),
            amount1 + amount2,
            "Total balance incorrect"
        );
    }

    function test_Withdraw_AsOwner() public {
        console.log("=== test_Withdraw_AsOwner ===");
        uint256 depositAmount = 10 ether;
        uint256 withdrawAmount = 3 ether;
        console.log("Deposit amount:", depositAmount);
        console.log("Withdraw amount:", withdrawAmount);

        vm.deal(address(bufferFund), depositAmount);

        uint256 initialBalance = user1.balance;
        console.log("User1 initial balance:", initialBalance);

        bufferFund.withdraw(user1, withdrawAmount);

        console.log("User1 balance after withdrawal:", user1.balance);
        console.log(
            "BufferFund balance after withdrawal:",
            bufferFund.getBalance()
        );

        assertEq(
            user1.balance,
            initialBalance + withdrawAmount,
            "Withdrawal not received"
        );
        assertEq(
            bufferFund.getBalance(),
            depositAmount - withdrawAmount,
            "BufferFund balance incorrect"
        );
    }

    function test_RevertWhen_WithdrawMoreThanBalance() public {
        console.log("=== test_RevertWhen_WithdrawMoreThanBalance ===");
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 2 ether;
        console.log("Deposit amount:", depositAmount);
        console.log("Withdraw amount (exceeds balance):", withdrawAmount);

        vm.deal(address(bufferFund), depositAmount);

        console.log("Expecting revert: Insufficient balance");
        vm.expectRevert("Insufficient balance");
        bufferFund.withdraw(user1, withdrawAmount);
    }

    function test_RevertWhen_WithdrawAsNonOwner() public {
        console.log("=== test_RevertWhen_WithdrawAsNonOwner ===");
        uint256 withdrawAmount = 1 ether;
        console.log("Withdraw amount:", withdrawAmount);
        console.log("Caller (non-owner):", user1);
        vm.deal(address(bufferFund), withdrawAmount);

        console.log("Expecting revert due to non-owner");
        vm.prank(user1);
        vm.expectRevert();
        bufferFund.withdraw(user1, withdrawAmount);
    }

    function test_WithdrawAll() public {
        console.log("=== test_WithdrawAll ===");
        uint256 depositAmount = 5 ether;
        console.log("Deposit amount:", depositAmount);
        vm.deal(address(bufferFund), depositAmount);

        bufferFund.withdraw(user1, depositAmount);

        console.log(
            "BufferFund balance after withdrawal:",
            bufferFund.getBalance()
        );
        assertEq(bufferFund.getBalance(), 0, "BufferFund should be empty");
    }

    function testFuzz_ReceiveETH(uint256 amount) public {
        console.log("=== testFuzz_ReceiveETH ===");
        amount = bound(amount, 0.001 ether, 1000 ether);
        console.log("Fuzz amount:", amount);

        vm.deal(user1, amount);

        vm.prank(user1);
        payable(address(bufferFund)).transfer(amount);

        console.log("BufferFund balance:", bufferFund.getBalance());
        assertEq(bufferFund.getBalance(), amount, "Fuzz: Balance incorrect");
    }

    function testFuzz_Withdraw(
        uint256 depositAmount,
        uint256 withdrawAmount
    ) public {
        console.log("=== testFuzz_Withdraw ===");
        depositAmount = bound(depositAmount, 1 ether, 1000 ether);
        withdrawAmount = bound(withdrawAmount, 0.1 ether, depositAmount);
        console.log("Fuzz deposit amount:", depositAmount);
        console.log("Fuzz withdraw amount:", withdrawAmount);

        vm.deal(address(bufferFund), depositAmount);

        bufferFund.withdraw(user1, withdrawAmount);

        console.log(
            "BufferFund balance after withdrawal:",
            bufferFund.getBalance()
        );
        console.log("User1 balance:", user1.balance);

        assertEq(
            bufferFund.getBalance(),
            depositAmount - withdrawAmount,
            "Fuzz: Withdraw balance incorrect"
        );
        assertEq(
            user1.balance,
            withdrawAmount,
            "Fuzz: User didn't receive withdrawal"
        );
    }

    function test_GetBalanceReflectsActualBalance() public {
        console.log("=== test_GetBalanceReflectsActualBalance ===");
        // Verify getBalance always matches actual balance
        console.log("Initial - getBalance():", bufferFund.getBalance());
        console.log("Initial - actual balance:", address(bufferFund).balance);
        assertEq(bufferFund.getBalance(), address(bufferFund).balance);

        vm.deal(address(bufferFund), 5 ether);
        console.log("After funding - getBalance():", bufferFund.getBalance());
        console.log(
            "After funding - actual balance:",
            address(bufferFund).balance
        );
        assertEq(bufferFund.getBalance(), address(bufferFund).balance);

        bufferFund.withdraw(user1, 2 ether);
        console.log(
            "After withdrawal - getBalance():",
            bufferFund.getBalance()
        );
        console.log(
            "After withdrawal - actual balance:",
            address(bufferFund).balance
        );
        assertEq(bufferFund.getBalance(), address(bufferFund).balance);
    }

    function test_OwnershipCheck() public {
        console.log("=== test_OwnershipCheck ===");
        // Verify current owner
        console.log("Contract owner:", bufferFund.owner());
        console.log("Expected owner:", owner);
        assertEq(bufferFund.owner(), owner, "Initial owner incorrect");

        // Only owner can withdraw
        vm.deal(address(bufferFund), 1 ether);

        // Non-owner cannot withdraw
        console.log("Testing non-owner withdrawal (should revert)");
        vm.prank(user1);
        vm.expectRevert();
        bufferFund.withdraw(user2, 1 ether);

        // Owner can withdraw
        console.log("Testing owner withdrawal");
        bufferFund.withdraw(user2, 1 ether);
        console.log("User2 balance after owner withdrawal:", user2.balance);
        assertEq(user2.balance, 1 ether, "Owner withdrawal failed");
    }
}
