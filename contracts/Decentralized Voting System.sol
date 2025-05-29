// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // State variables
    address public owner;
    uint256 public votingEnd;
    bool public votingActive;
    
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    
    struct Voter {
        bool hasVoted;
        uint256 votedCandidateId;
        bool isRegistered;
    }
    
    mapping(address => Voter) public voters;
    mapping(uint256 => Candidate) public candidates;
    uint256 public candidatesCount;
    uint256 public totalVotes;
    
    // Events
    event VoterRegistered(address indexed voter);
    event CandidateAdded(uint256 indexed candidateId, string name);
    event VoteCast(address indexed voter, uint256 indexed candidateId);
    event VotingStarted(uint256 endTime);
    event VotingEnded();
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyDuringVoting() {
        require(votingActive && block.timestamp < votingEnd, "Voting is not active");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "Voter not registered");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        votingActive = false;
    }
    
    // Core Function 1: Register voters and manage candidates
    function registerVoter(address _voter) external onlyOwner {
        require(!voters[_voter].isRegistered, "Voter already registered");
        require(!votingActive, "Cannot register during active voting");
        
        voters[_voter].isRegistered = true;
        voters[_voter].hasVoted = false;
        
        emit VoterRegistered(_voter);
    }
    
    function addCandidate(string memory _name) external onlyOwner {
        require(!votingActive, "Cannot add candidates during active voting");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        
        emit CandidateAdded(candidatesCount, _name);
    }
    
    function startVoting(uint256 _durationInMinutes) external onlyOwner {
        require(!votingActive, "Voting is already active");
        require(candidatesCount > 0, "No candidates available");
        require(_durationInMinutes > 0, "Duration must be greater than 0");
        
        votingEnd = block.timestamp + (_durationInMinutes * 1 minutes);
        votingActive = true;
        
        emit VotingStarted(votingEnd);
    }
    
    // Core Function 2: Cast votes
    function vote(uint256 _candidateId) external onlyDuringVoting onlyRegisteredVoter {
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = _candidateId;
        
        candidates[_candidateId].voteCount++;
        totalVotes++;
        
        emit VoteCast(msg.sender, _candidateId);
    }
    
    // Core Function 3: Get results and manage voting lifecycle
    function endVoting() external onlyOwner {
        require(votingActive, "Voting is not active");
        
        votingActive = false;
        emit VotingEnded();
    }
    
    function getResults() external view returns (Candidate[] memory) {
        require(!votingActive || block.timestamp >= votingEnd, "Voting is still ongoing");
        
        Candidate[] memory results = new Candidate[](candidatesCount);
        for (uint256 i = 1; i <= candidatesCount; i++) {
            results[i-1] = candidates[i];
        }
        return results;
    }
    
    function getWinner() external view returns (string memory winnerName, uint256 winnerVotes) {
        require(!votingActive || block.timestamp >= votingEnd, "Voting is still ongoing");
        require(candidatesCount > 0, "No candidates available");
        
        uint256 winningVoteCount = 0;
        uint256 winningCandidateId = 0;
        
        for (uint256 i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }
        
        return (candidates[winningCandidateId].name, winningVoteCount);
    }
    
    // Utility functions
    function getVotingStatus() external view returns (bool active, uint256 endTime, uint256 remainingTime) {
        active = votingActive && block.timestamp < votingEnd;
        endTime = votingEnd;
        remainingTime = votingActive && block.timestamp < votingEnd ? votingEnd - block.timestamp : 0;
    }
    
    function getVoterInfo(address _voter) external view returns (bool registered, bool hasVoted, uint256 votedFor) {
        Voter memory voter = voters[_voter];
        return (voter.isRegistered, voter.hasVoted, voter.votedCandidateId);
    }
    
    function getCandidateInfo(uint256 _candidateId) external view returns (string memory name, uint256 voteCount) {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.name, candidate.voteCount);
    }
}
