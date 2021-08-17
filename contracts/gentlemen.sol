pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Gentlemen
 * @dev Implements betting framework.
 */
contract Gentlemen {
 
    struct Wager {
        uint256 amount; // The amount of the wager
        bytes32 description; // A description of the wager
        mapping(address => bool) votes; // Votes for success
    }
    
    uint256 private expires;
    mapping(address => bool) private approved;
    mapping(address => Wager) public participants;
    
    // creates the contract with a whitelist of particpants and
    // an expiration time in days from creation
    constructor(address[] memory whitelist, uint duration) payable {
        require(whitelist.length > 3, "Must have at least 3 particpants");
        require(duration > 0, "Must end in the future");
        
        for (uint p = 0; p < whitelist.length; p++) {
            approved[whitelist[p]] = true;
        }
        
        expires = block.timestamp + (86400 * duration);
    }

    // Allows a participant to make their wager
    function wager(bytes32 description) public payable {
        require(approved[msg.sender], "Non particpants cannot wager.");
        require(participants[msg.sender].amount == 0, "Participant has already wagered");
        
        participants[msg.sender] = Wager(msg.value, description, mapping(address => bool));
    }
    
    // Allows participants to vote on each others success
    function vote(address votee) public {
        
        require(
            participants[votee] != msg.sender,
            "Cannot vote for self."
        );
        require(
            !participants[votee].votes[msg.sender],
            "Participant has already voted"
        );
        
        // Place the voter into the votes list
        participants[votee].votes.push(msg.sender);
    }
   
    // function voterHasVoted(address votee, address voter) private view returns (bool) {
    //     for (uint p = 0; p < participants[votee].votes.length; p++) {
    //         if (participants[votee].votes[p] == voter) {
    //             return true;
    //         }
    //     }
        
    //     return false;
    // }
}