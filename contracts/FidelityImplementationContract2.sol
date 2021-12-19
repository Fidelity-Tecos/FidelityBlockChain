pragma solidity 0.8.10;

//pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FidelityImplementationContract2 is OwnableUpgradeable, ERC20Upgradeable {
	using SafeMathUpgradeable for uint256;
	
	 // *-*-*-*-*-*-*_Attibutes_*-*-*-*-*-*-*

	// *-*-*-*-*-*-*_Constructor_*-*-*-*-*-*-*
	
    // struct EchelonReward is used to build rewards echelons
    struct EchelonReward {
        uint256 echelonMaxValue;
        uint256 percentage;
    }

    // stakeholders array
    address[] internal stakeholders;

    // minimum balance value since the last rewards distribution
    mapping(address => uint256) internal rewardableBalance;

    // timestamp to store when the next reward distribution will be possible
    uint256 internal nextRewardsAvailableTime;

    // duration between each reward distribution
    uint256 internal rewardsDuration;

    // reward percentage by tokens
    EchelonReward[] internal rewardsPercentageByTokens;


    // *-*-*-*-*-*-*_Constructor_*-*-*-*-*-*-*
	
	function init(uint256 initialTokens) initializer  public {
		// SET THE OWNER HERE
		__Ownable_init();
		__ERC20_init("FidelityToken", "FT");
		
		_mint(msg.sender, initialTokens * 10 ** uint256(decimals()));
		fillRewardsPercentageByTokensOnStart();
		nextRewardsAvailableTime = block.timestamp.add(rewardsDuration);
		rewardsDuration = 2 minutes;
	}

    // *-*-*-*-*-*-*_Stakeholders_*-*-*-*-*-*-*

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
    */
    function isStakeholder(address _address)
        public
        onlyOwner
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
    */
    function addStakeholder(address _stakeholder)
        public
        onlyOwner
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) {
            stakeholders.push(_stakeholder);
            rewardableBalance[_stakeholder] = 0;
        }
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
    */
    function removeStakeholder(address _stakeholder)
        public
        onlyOwner
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
            rewardableBalance[_stakeholder] = 0;
        } 
    }


    // *-*-*-*-*-*-*_Rewards_*-*-*-*-*-*-*

    /** 
     * @notice A simple method that calculates the rewards of the given stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
    */
    function calculateReward(address _stakeholder)
        public
        onlyOwner
        view
        returns(uint256)
    {
        return getRewardableBalanceByStakeholder(_stakeholder) * getRewardPercentage(_stakeholder) / 100;
    }

    /**
     * @notice A method to get the rewardable balance of the given stakeholder.
     * @param _stakeholder The stakeholder.
     * @return The amount of the rewardable tokens of the given stakeholder
    */
    function getRewardableBalanceByStakeholder(address _stakeholder)
        public
        onlyOwner
        view
        returns(uint256)
    {
        return rewardableBalance[_stakeholder];
    }

    /**
     * @notice A method to get the reward percentage by balance.
     * @param _stakeholder The stakeholder.
     * @return The reward percentage according to the stakeholder's balance
    */
    function getRewardPercentage(address _stakeholder)
        public
        onlyOwner
        view
        returns(uint256)
    {
        if (0 != rewardsPercentageByTokens.length) {
            for (uint index = rewardsPercentageByTokens.length; index > 0; index--) {
                if (rewardableBalance[_stakeholder] >= rewardsPercentageByTokens[index - 1].echelonMaxValue) {
                    return rewardsPercentageByTokens[index - 1].percentage;
                }
            }
        }
        return 0;
    }

    /**
     * @notice A method to get the reward percentage by balance.
     * @return The reward percentage according to the stakeholder's balance
    */
    function getRewardsPercentageByTokens() public onlyOwner view returns (EchelonReward[] memory) {
        return rewardsPercentageByTokens;
    }

    /**
     * @notice A method to distribute rewards to all stakeholders.
    */
    function distributeRewards() 
        public
        onlyOwner
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            if (block.timestamp > nextRewardsAvailableTime) {
                updateRewardableBalancePerAddress(stakeholder);
                uint256 reward = calculateReward(stakeholder);
                increaseAllowance(owner(), reward);
                transferFrom(owner(), stakeholder, reward);
                rewardableBalance[stakeholder] = balanceOf(stakeholder);
            }
        }
        nextRewardsAvailableTime = block.timestamp.add(rewardsDuration);
    }

    /**
     * @notice A method to update the rewards percentage echlons.
     * @param newEchlonArray The new rewards echlons.
    */
    function updateRewardsPercentageByTokens(EchelonReward[] memory newEchlonArray) public onlyOwner {
        if (0 != newEchlonArray.length) {
            delete rewardsPercentageByTokens;
            for (uint index = 0; index < newEchlonArray.length; index++) {
                EchelonReward memory echelon;
                echelon.echelonMaxValue = newEchlonArray[index].echelonMaxValue * 10 ** uint256(decimals());
                echelon.percentage = newEchlonArray[index].percentage;
                rewardsPercentageByTokens[index] = echelon;
            }
        }
    }

    /**
     * @notice A method to initialize the reward percntages.
    */
    function fillRewardsPercentageByTokensOnStart() private onlyOwner {
        rewardsPercentageByTokens.push(EchelonReward(
            {
                echelonMaxValue : 100 * 10 ** uint256(decimals()),
                percentage : 1
            }));

        rewardsPercentageByTokens.push(EchelonReward(
            {
                echelonMaxValue : 500 * 10 ** uint256(decimals()),
                percentage : 2
            }));

        rewardsPercentageByTokens.push(EchelonReward(
            {
                echelonMaxValue : 1000 * 10 ** uint256(decimals()),
                percentage : 3
            }));

        rewardsPercentageByTokens.push(EchelonReward(
            {
                echelonMaxValue : 10000 * 10 ** uint256(decimals()),
                percentage : 4
            }));
        
        rewardsPercentageByTokens.push(EchelonReward(
            {
                echelonMaxValue : 50000 * 10 ** uint256(decimals()),
                percentage : 5
            }));
    }

    /**
     * @notice A method to update the rewardable balance for the given stakeholder.
     * @param _stakeholder The stakeholder.
    */
    function updateRewardableBalancePerAddress(address _stakeholder) public onlyOwner {
        if (balanceOf(_stakeholder) < rewardableBalance[_stakeholder]) {
            rewardableBalance[_stakeholder] = balanceOf(_stakeholder);
        }
    }

    /**
     * @notice A method to update the rewardable balance for all the stakeholders.
    */
    function updateRewardableBalances() public onlyOwner {
        for (uint index = 0; index < stakeholders.length; index++) {
            updateRewardableBalancePerAddress(stakeholders[index]);
        } 
    }


    // *-*-*-*-*-*-*_Transactions_*-*-*-*-*-*-*

    /**
     * @notice A method to send tokens from the retailer to the customer.
     * @param retailer The retailer address.
     * @param customer The customer address.
     * @param tokens The amount of tokens to send.
    */
    function sendTokensFromRetailerToCustomer(address retailer, address customer, uint256 tokens) public onlyOwner {
        increaseAllowance(retailer, tokens * 10 ** uint256(decimals()));
        transferFrom(retailer, customer, tokens * 10 ** uint256(decimals()));
        updateRewardableBalancePerAddress(customer);
        updateRewardableBalancePerAddress(retailer);
    }

    /**
     * @notice A method to send tokens from the customer to the retailer.
     * @param retailer The retailer address.
     * @param customer The customer address.
     * @param tokens The amount of tokens to send.
    */
    function sendTokensFromCustomerToRetailer(address retailer, address customer, uint256 tokens) public onlyOwner {
        increaseAllowance(customer, tokens * 10 ** uint256(decimals()));
        transferFrom(customer, retailer, tokens * 10 ** uint256(decimals()));
        updateRewardableBalancePerAddress(customer);
        updateRewardableBalancePerAddress(retailer);
    }

    /**
     * @notice A method to enable customers to send tokens from one retailer to another.
     * @param retailerSource The retailer source address.
     * @param walletSource The customer address in the source retailer.
     * @param walletDestination The customer address in the target retailer.
     * @param tokensToSend The amount of tokens to send.
     * @param feesForFidelityPercent The percentage of transaction fees for Fidelity.
     * @param feesForRetailerSourcePercent The percentage of transaction fees for the source retailer.
    */
    function tansfertFromRetailerToAnother(address retailerSource, address walletSource, address walletDestination, uint256 tokensToSend,
            uint256 feesForFidelityPercent, uint256 feesForRetailerSourcePercent) public onlyOwner {
                
        uint256 feesForFidelity = ((tokensToSend * feesForFidelityPercent) / 100) * 10 ** uint256(decimals());
        uint256 feesForRetailerSource = ((tokensToSend * feesForRetailerSourcePercent) / 100) * 10 ** uint256(decimals());
        
        increaseAllowance(walletSource, (tokensToSend * 10 ** uint256(decimals())) - feesForFidelity - feesForRetailerSource);
        transferFrom(walletSource, walletDestination, (tokensToSend * 10 ** uint256(decimals())) - feesForFidelity - feesForRetailerSource);
        
        increaseAllowance(walletSource, feesForRetailerSource);
        transferFrom(walletSource, retailerSource, feesForRetailerSource);
        
        increaseAllowance(walletSource, feesForFidelity);
        transferFrom(walletSource, owner(), feesForFidelity);
        
        updateRewardableBalancePerAddress(retailerSource);
        updateRewardableBalancePerAddress(walletSource);
        updateRewardableBalancePerAddress(walletDestination);
        updateRewardableBalancePerAddress(owner());
    }

    /**
     * @notice A method to mint extra tokens.
     * @param tokens The amount of tokens to mint.
    */
    function mintExtraTokens(uint256 tokens) public onlyOwner {
        _mint(owner(), tokens * 10 ** uint256(decimals()));
    }
    
    /**
     * @notice A method to burn tokens.
     * @param tokens The amount of tokens to burn.
    */
    function burnTokens(uint256 tokens) public onlyOwner {
        _burn(owner(), tokens * 10 ** uint256(decimals()));
    }
	
	/**
     * @notice A method to set the reward duration.
     * @param newRewardsDuration The new reward duration.
    */
    function setRewardsDuration(uint256 newRewardsDuration) public onlyOwner {
        rewardsDuration = newRewardsDuration;
    }
	
	/**
     * @notice A method to get the reward duration.
     * @return uint256 The reward duration
    */
    function getRewardsDuration()
        public
        onlyOwner
        view
        returns(uint256)
    {
        return rewardsDuration;
    }
}