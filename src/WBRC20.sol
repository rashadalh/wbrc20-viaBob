// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { HelloBitcoin } from "./HelloBitcoin.sol";
import { BitcoinTx } from "@bob-collective/bob/bridge/BitcoinTx.sol";
import { IRelay } from "@bob-collective/bob/bridge/IRelay.sol";
import { TestLightRelay} from "@bob-collective/bob/relay/TestLightRelay.sol";
import { stdStorage, StdStorage, Test, console } from "forge-std/Test.sol";
import { BridgeState } from "@bob-collective/bob/bridge/BridgeState.sol";

using SafeERC20 for IERC20;

contract WBRC20 is ERC20Capped, ERC20Burnable {
    using BitcoinTx for BridgeState.Storage;

    address payable public owner;
    uint256 public blockReward;

    BridgeState.Storage internal relay;
    TestLightRelay internal testLightRelay;

    /**
     * @dev The address of the ERC-20 contract. You can use this variable for any ERC-20 token,
     * not just USDT (Tether). Make sure to set this to the appropriate ERC-20 contract address.
     */
    IERC20 public usdtContractAddress;

    constructor(
        uint256 cap,
        uint256 reward,
        string memory name,
        string memory ticker,
        IRelay _relay, address _usdtContractAddress
    ) ERC20(name, ticker) ERC20Capped(cap * (10 ** decimals())) {
        owner = payable(msg.sender);
        _mint(owner, 50000000 * (10 ** decimals()));
        blockReward = reward * (10 ** decimals()); // Setting block reward for first deploy
        
        relay.relay = _relay;
        relay.txProofDifficultyFactor = 1;
        testLightRelay = TestLightRelay(address(relay.relay));
        usdtContractAddress = IERC20(_usdtContractAddress);
    }

    // Setting miner reward
    function _mintMinerReward() internal {
        _mint(block.coinbase, blockReward);
    }

    // block.conbase validation for rewarding the minder; prevents miner from manipulating teh token
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        if (
            from != block.coinbase &&
            to != block.coinbase &&
            block.coinbase != address(0)
        ) {
            _mintMinerReward();
        }
        super._beforeTokenTransfer(from, to, value);
    }

    function mintWBRC20(
        address to,
        uint256 amount,
        BitcoinTx.Info calldata transaction,
        BitcoinTx.Proof calldata proof
    ) public onlyOwner {
        // Validate the BTC transaction proof using the relay
        // NOTE: will revert if proof is invalid
        relay.validateProof(transaction, proof);
        _mint(to, amount);
    }

    function redeemWBRC20(
        uint256 amount
    ) public {
        // tranfer WBRC-20 from user to the bridge
        transferFrom(msg.sender, address(this), amount);
        
        // Burn the WBRC-20
        _burn(msg.sender, amount);

        // Make call to tBTC to redeem the tBTC
        // tBTC.redeem(amount);
        revert("Not implemented");
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20Capped, ERC20) {
        require(
            ERC20.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

      //Destroying the contract
    function destroyContract() public onlyOwner {
        selfdestruct(owner);
    }

    // Set block rewards
    function setBlockReward(uint256 reward) public onlyOwner {
        blockReward = reward * (10 ** decimals());
    }

    //reusable modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
}