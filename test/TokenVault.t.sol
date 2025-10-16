pragma solidity ^0.8.0;
import {Test, console2} from "forge-std/Test.sol";
import {TokenVault} from "../src/TokenVault.sol";

contract TokenVaultTest is Test {
    TokenVault public vault;
    address public user1 = address(0xBEEF);
    uint256 public constant INITIAL_BALANCE = 10 ether;

    function setUp() public {
        // 1. Deploy the contract
        vault = new TokenVault();

        // 2. Fund the test account (user1) for transactions
        vm.deal(user1, INITIAL_BALANCE);
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
    uint256 sumOfBalances = 
        vault.balances(user1) + 
        vault.balances(address(0xDEAD)); // Imagine tracking a few key addresses

    assertEq(vault.totalValue(), sumOfBalances, "Invariant violated: totalValue != sum of balances");
}

function testCompareWithdrawGas() public {
    uint256 depositAmount = 1 ether;
    uint256 withdrawAmount = 0.1 ether;

    vm.deal(user1, depositAmount);
    vm.prank(user1);
    vault.deposit{value: depositAmount}(depositAmount);
    
    // 1. Call the optimized version
    vm.prank(user1);
    vault.withdrawOptimized(withdrawAmount);
    
    // 2. Call the unoptimized version (requires resetting the state, usually in a separate test)
    // To properly compare, you should call them in separate test functions:
    // function testWithdrawOptimized() public { /* ... call vault.withdrawOptimized ... */ }
    // function testWithdrawUnoptimized() public { /* ... call vault.withdrawUnoptimized ... */ }
    
    // In this example, we'll just run the report on all functions.
}
}
