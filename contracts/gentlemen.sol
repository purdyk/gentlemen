pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Gentlemen
 * @dev Implements betting framework.
 * 
 * SPDX-License-Identifier: CC0-1.0
 */
contract Gentlemen {
 
    struct Wager {
        uint256 amount; // The amount of the wager
        uint256 paid; // The amount paid out on this wager
        bytes32 description; // A description of the wager
    }
    
    uint256 private expires;
    address[] private participants;
    mapping(address => bool) private approved;
    mapping(address => Wager) public wagers;
    
    // Votes for success, this cannot be stored on Wager due to
    // structural limitations
    // First level is for the particpant, second level is for the votes
    mapping(address => mapping(address => bool)) private votes;
    
    // creates the contract with a whitelist of particpants and
    // an expiration time in days from creation
    constructor(address[] memory whitelist, uint duration) {
        require(whitelist.length > 3, "Must have at least 3 particpants");
        require(duration > 0, "Must end in the future");
        
        participants = whitelist;
        
        for (uint p = 0; p < whitelist.length; p++) {
            approved[whitelist[p]] = true;
        }
        
        expires = block.timestamp + (86400 * duration);
    }

    // Allows a participant to make their wager
    function wager(bytes32 description) public payable {
        require(!isExpired(), "Voting has closed");
        require(approved[msg.sender], "Non particpants cannot wager.");
        require(wagers[msg.sender].amount == 0, "Participant has already wagered");
        
        wagers[msg.sender] = Wager(msg.value, 0, description);
    }
    
    // Allows participants to vote on each others success
    function vote(address votee) public {
        require(!isExpired(), "Voting has closed");
        require(votee != msg.sender, "Cannot vote for self.");
        require(votes[votee][msg.sender], "Participant has already voted");
        require(approved[msg.sender], "Non participants cannot vote");
        
        // Place the voter into the votes list
        votes[votee][msg.sender] = true;
    }
    
    function isApproved(address participant) public view returns (bool) {
        uint count;
        
        for (uint i = 0; i < participants.length; i++) {
            if (votes[participant][participants[i]]) {
                count += 1;
            }
        }
        
        return count >= participants.length - 2;
    }
    
    function isExpired() public view returns (bool) {
        return block.timestamp >= expires;
    }
    
    // This expires the bet, and pays out any unpaid 
    // wagers.  It also splits up the failures and disperses them
    function expire() public {
        require(isExpired(), "Expire must be called after the expiration date.");
        
        uint256 pool;
        uint successful;
        
        // Count successes and build the failure pool
        for (uint i = 0; i < participants.length; i++) {
            
            address current = participants[i];
            
            if (isApproved(current)) {
                successful += 1;
            } else {
                pool += wagers[current].amount;
            }
        }
        
        uint256 bonus = pool / successful;
        
        // Perform the payouts
        for (uint i = 0; i < participants.length; i++) {
            address payable current = payable(participants[i]);
            if (isApproved(current)) {
                uint256 toPay = bonus;
            
                if (wagers[current].paid == 0) {
                    toPay += wagers[current].amount;
                    wagers[current].paid = wagers[current].amount;
                }
            
                current.transfer(toPay);
            }
        }
    }
}