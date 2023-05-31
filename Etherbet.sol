// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract Etherbet is VRFConsumerBaseV2, ConfirmedOwner {
    //CHAINLINK VRF Variables set for POLYGON MUMBAI TESTNET
    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 2500000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    //Gambling Contract Code
    address public manager; // Address of the contract manager
    uint256 public totalAmount; // Total amount collected from participants
    uint256 public platformFee; // Fee percentage charged by the platform
    uint256 public numOfAccounts; // Number of accounts participating in the raffle
    uint256 public winningIndex; // Index of the winning account
    address[] public participants; // Array of participant addresses
    IERC20 public token; // ERC20 token contract

    event WinnerSelected(address winner, uint256 amount);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    /**
     * HARDCODED FOR POLYGON MUMBAI TESTNET
     * COORDINATOR: 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
     */
    constructor(
        address _token,
        uint256 _platformFee,
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
        ConfirmedOwner(msg.sender)
    {
        manager = msg.sender;
        token = IERC20(_token);
        platformFee = _platformFee;
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = subscriptionId;
    }

    //ChainLink Random Number Functions
    //this function receives random words from Chainlink Oracle
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);

        // uint randomness = uint(keccak256(abi.encode(block.timestamp, block.difficulty, participants.length)));
        
        winningIndex = _randomWords[0] % numOfAccounts;
        address winner = participants[winningIndex];
        uint256 amount = calculatePayout(totalAmount);

        emit WinnerSelected(winner, amount);

        // Transfer the payout to the winner
        token.transfer(winner, amount);
        // Reset the contract for the next round
        resetContract();
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    // Function to participate in the Raffle
    function participate(uint256 amount) external {
        require(amount > 10000000000000000000, "Amount should be greater than 10 tokens");
        require(
            participants.length < numOfAccounts,
            "The maximum number of participants has been reached"
        );

        token.transferFrom(msg.sender, address(this), amount);

        participants.push(msg.sender);
        totalAmount += amount;
    }

    // Function to select the winner
    function selectWinner() external onlyOwner returns (uint256 requestId) {
        require(
            participants.length == numOfAccounts,
            "Not all accounts have participated yet"
        );
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    // Function to calculate the payout amount
    function calculatePayout(uint256 amount) private view returns (uint256) {
        uint256 platformFeeAmount = (amount * platformFee) / 100;
        return amount - platformFeeAmount;
    }

    // Function to reset the contract for the next round
    function resetContract() private {
        delete participants;
        totalAmount = 0;
        winningIndex = 0;
    }

    // Function to withdraw any remaining tokens from the contract
    function withdrawTokens() external onlyOwner {
        token.transfer(manager, token.balanceOf(address(this)));
    }

    // Function to set the number of accounts participating in the raffle
    function setNumOfAccounts(uint256 _numOfAccounts) external onlyOwner {
        require(
            participants.length == 0,
            "Cannot change the number of accounts after participants have joined"
        );
        numOfAccounts = _numOfAccounts;
    }
}