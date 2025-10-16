pragma solidity ^0.8.0;
import {Test, console2} from "forge-std/Test.sol";
import {TokenVault} from "../src/TokenVault.sol";

contract TokenVaultTest is Test {
    TokenVault public vault;
    address public user1 = address(0xBEEF);
    address public user2 = address(0xBEEF11);
    uint256 public constant INITIAL_BALANCE = 10 ether;
    uint256 public constant WITHDRAW_AMOUNT = 0.1 ether;
    function setUp() public {
        // 1. Deploy the contract
        vault = new TokenVault();

        // 2. Fund the test account (user1) for transactions
        vm.deal(user1, INITIAL_BALANCE);
        vm.deal(user2, INITIAL_BALANCE);
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;

        // Use a cheat code to act as user1 and send value
        vm.startPrank(user1);
        vault.deposit{value: depositAmount}(depositAmount);
        vm.stopPrank();

        // Assertions
        assertEq(
            vault.balances(user1),
            depositAmount,
            "User balance is incorrect"
        );
        assertEq(vault.totalValue(), depositAmount, "Total value is incorrect");
    }

    // Example test for a failing scenario (revert)
    function testRevertDeposit_WrongAmount() public {
        uint256 sentAmount = 1 ether;
        uint256 expectedAmount = 2 ether;

        // Expect a specific revert string
        vm.expectRevert("Must send exact ETH amount");

        // The transaction that should revert
        vault.deposit{value: sentAmount}(expectedAmount);
    }

    // Fuzz test for the deposit function
    function testFuzz_Deposit(uint96 amount) public {
        // 1. Set a constraint using vm.assume()
        // We only want to test amounts > 0 and <= our initial balance
        vm.assume(amount > 0 && amount <= INITIAL_BALANCE);

        uint256 preVaultBalance = address(vault).balance;
        uint256 preUserBalance = vault.balances(user1);

        // 2. Execute with random 'amount'
        vm.startPrank(user1);
        vault.deposit{value: amount}(amount);
        vm.stopPrank();

        // 3. Assert a "property" that should always hold true
        assertEq(
            vault.balances(user1),
            preUserBalance + amount,
            "User balance property violated"
        );
        assertEq(
            address(vault).balance,
            preVaultBalance + amount,
            "Vault ETH balance property violated"
        );
    }

    // Invariant: The totalValue must always equal the sum of all user balances
    function invariant_TotalValueEqualsSumOfBalances() public view {
        // This invariant function is run after every random call in the sequence.
        uint256 sumOfBalances = vault.balances(user1) +
            vault.balances(address(0xDEAD)); // Imagine tracking a few key addresses

        assertEq(
            vault.totalValue(),
            sumOfBalances,
            "Invariant violated: totalValue != sum of balances"
        );
    }

    function testCompareWithdrawGas_Optimized() public {
        // This test runs completely independently of the unoptimized one,
        // ensuring a fresh state (cold storage) for the withdrawal.

        // We're withdrawing only part of the deposit, so the vault's state
        // (e.g., balance, shares) will be written to for the first time
        // in this specific test function's execution.
        uint256 preUserBalance = vault.balances(user1);
        uint256 amount = 1 ether;
        // 2. Execute with random 'amount'
        vm.startPrank(user1);
        vault.deposit{value: amount}(amount);
        vault.withdrawOptimized(WITHDRAW_AMOUNT);
        vm.stopPrank();

        // Note: No need for assertions here unless you are specifically testing
        // correctness. The primary goal is the gas report.
    }

    // 2. Test for the Unoptimized version
    function testCompareWithdrawGas_Unoptimized() public {
        // This test also runs independently, ensuring a fresh state (cold storage)
        // for the unoptimized withdrawal.
        uint256 preUserBalance = vault.balances(user2);
        uint256 amount = 1 ether;
        // 2. Execute with random 'amount'
        vm.startPrank(user2);
        vault.deposit{value: amount}(amount);
        // If your Vault contract has an unoptimized function named withdrawUnoptimized:
        vault.withdrawUnoptimized(WITHDRAW_AMOUNT);
        vm.stopPrank();
    }
}
