pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;

//import "./Able.sol";
//import "./Doers.sol";
import "./Creators.sol";
import "./DoitToken.sol";


contract InputFactor is Controlled {
    
    address public deployer;

    Creators public doers;

    // Service Services;

    // Plan Plans;

    // Promise Promises;

    // Fulfillment Fulfillments;

    uint public promiseCount;
    uint public orderCount;
    uint public fulfillmentCount;

    modifier onlyCreators {
        if (!doers.isCreator(msg.sender)) 
        revert();
        _;
    }    

    modifier onlyDoers {
        if (!doers.isDoer(msg.sender)) 
        revert();
        _;
    }

    function InputFactor(Creators abs) public {
        fulfillmentCount = 0;
        deployer = msg.sender;
        doers = abs;
        Controlled.registerContract("InpuFactors", this);
    }

    // Data -> Plan
    // Produce a Plan
        // struct Plan {
		// bytes32 conditionP;
		// mapping(bytes32 => Service) service;
        // mapping(bytes32 => Service[]) services;
        // mapping(bytes32 => string) project;
		// bytes32 conditionQ;
		// }
        // mapping(bytes32 => Plan) plans;
    // function concept(bytes32 _wish, bytes32 _goal, bytes32 _preConditions) returns (Plan); // STUB
    // Examples
    // desire(aWish, aGoal, aPreconditions, aProjectUrl);
    // url = keccak256(aUrl)
        // struct Service {
		// bytes32 conditionP;
		// Promise taskT;
		// bytes32 conditionQ;
		// } 

    function plan(bytes32 _intention, bytes32 _desire, bytes32 _preConditions, string _projectUrl) public payable onlyCreators {
        Controlled.plans[_intention].conditionQ = Doers(msg.sender).getDesire(_desire).goal; // Creator and project share a goal  
        Controlled.plans[_intention].conditionP = _preConditions; // pCondition of the curate that will define the concept.
        bytes32 url = keccak256(_projectUrl);
        Controlled.plans[_intention].ipfs[url] = _projectUrl; // main url of the project repo.
    }

    function plan(bytes32 _intention, bytes32 _serviceId, bytes32 _pConditions, bytes32 _qConditions) public payable onlyDoers {
        require(Controlled.plans[_intention].conditionP == Controlled.bdi[tx.origin].beliefs.hash); // curate meets the pCondition
        Controlled.plans[_intention].service[_serviceId].conditionP.hash = _pConditions;
        Controlled.plans[_intention].service[_serviceId].conditionQ = _qConditions;
    }
    
    // pCondition must be present before project is started
    // qCondition must be present before project is closed
    function plan(bytes32 _intention, bytes32 _prerequisites, string _projectUrl, bytes32 _verity) public payable onlyDoers {
        require(Controlled.bdi[tx.origin].beliefs.hash == Controlled.plans[_intention].conditionP); // curate meets the pCondition
        Controlled.plans[_intention].conditionP = keccak256(_prerequisites, Controlled.plans[_intention].conditionP);
        bytes32 url = keccak256(_projectUrl);
        Controlled.plans[_intention].ipfs[url] = _projectUrl; // additional urls of project repo.
        Controlled.plans[_intention].conditionQ = keccak256(_verity, Controlled.plans[_intention].conditionQ);
        Controlled.allPlans.push(_intention);
    }      

    function promise(bytes32 _intention, bytes32 _desire, bytes32 _serviceId, uint _time, string _thing) public payable onlyDoers {
        require(Controlled.bdi[tx.origin].beliefs.hash == Controlled.plans[_intention].service[_serviceId].conditionP.hash);
        require(Controlled.bdi[tx.origin].desires[_desire].goal == Controlled.plans[_intention].service[_serviceId].conditionQ);
        require((_time > block.timestamp) || (_time < Controlled.plans[_intention].service[_serviceId].expire));
        require(msg.value > 0);
        require(Controlled.bdi[tx.origin].beliefs.index > Controlled.bdi[Controlled.plans[_intention].service[_serviceId].taskT.doer].beliefs.index);
        bytes32 eoi = keccak256(msg.sender, _thing);
        Controlled.plans[_intention].service[_serviceId].taskT = Promise({doer: tx.origin, thing: _thing, timeAlt: _time, value: msg.value, hash: eoi});
        Controlled.Promises[tx.origin].push(_serviceId);
        promiseCount++;
        Controlled.promiseCount++; //!!! COULD REMOVE ONE COUNTER, LEFT HERE FOR DEBUGGING
        }

    function order(bytes32 _intention, bytes32 _serviceId, bool _check, string thing, string proof) public payable onlyDoers {
        // Validate existing promise.
        if (Controlled.bdi[Controlled.plans[_intention].service[_serviceId].taskT.doer].intentions[_check].status != 
        Controlled.Agent.ACTIVE) {
            Controlled.Promise storage reset;
            Controlled.plans[_intention].service[_serviceId].taskT = reset;
            }
        bytes32 lso = keccak256(msg.sender, _serviceId);
        require(block.timestamp < Controlled.plans[_intention].service[lso].expire);
        bytes32 verity = keccak256(msg.sender, proof);
        Controlled.Fulfillment storage checker;
        orders[verity] = Order({doer: msg.sender, promise: Controlled.plans[_intention].service[lso].taskT.hash, proof: proof, timestamp: block.timestamp, check: checker, hash: verity});
        Controlled.orderCount++;
        }

    function fulfill(bytes32 _intention, bytes32 _verity, bytes32 _thing) public payable onlyDoers {
        // Validate existing promise.
        Controlled.orders[_verity].hash = _thing;
        _verity = keccak256(msg.sender, _verity);
        orders[_verity].check = Fulfillment({prover: tx.origin, timestamp: block.timestamp, hash: _verity, complete: true});
        Controlled.fulfillmentCount++;
        // function setReputation(Controlled.Intention _service, bool _intention) internal onlyDoer {
        //     myBDI.beliefs.reputation = _service;  !!! Working on
		}

    function getDeployer() internal constant returns (address) {
        return deployer;
    }

    function getDoers() internal constant returns (Creators) {
        return doers;
    }

    function getPromiseCount() internal constant returns (uint) {
        return promiseCount;
    }

    function getFulfillmentCount() internal constant returns (uint) {
        return fulfillmentCount;
    }
////////////////
// Events
////////////////
    event PlanEvent(address indexed _from, address indexed _to, uint256 _amount);
    event PromiseEvent(address indexed _from, address indexed _to, uint256 _amount);
    event Fulfill(address indexed _from, address indexed _to, uint256 _amount);
}

contract FactorPayout is DoitToken {

bytes32 public currentChallenge;                         // The coin starts with a challenge
uint public timeOfLastProof;                             // Variable to keep track of when rewards were given
uint public difficulty = 10**32;                         // Difficulty starts reasonably low
uint256 amount;

function FactorPayout() internal {
    Controlled.registerContract("InputFactor", this);
    }

function payout(uint nonce, bytes32 _verity, bytes32 _intention, bytes32 _serviceId) internal {
    bytes8 n = bytes8(keccak256(nonce, currentChallenge));    // Generate a random hash based on input
    require(n >= bytes8(difficulty));                   // Check if it's under the difficulty
    uint timeSinceLastProof = (now - timeOfLastProof);  // Calculate time since last reward was given
    require(timeSinceLastProof >= 5 seconds);         // Rewards cannot be given too quickly
    require(orders[_verity].timestamp < Controlled.plans[_intention].service[_serviceId].expire);
    uint payableTime = (Controlled.plans[_intention].service[_serviceId].timeOpt * 
    ((Controlled.plans[_intention].service[_serviceId].expire - orders[_verity].timestamp) /
    (Controlled.plans[_intention].service[_serviceId].expire - Controlled.plans[_intention].service[_serviceId].timeOpt)));
    amount += payableTime / 60 seconds * 42 / 10;  // The reward to the winner grows by the minute
    difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;  // Adjusts the difficulty
    approveAndCall(msg.sender, amount, "");

    timeOfLastProof = now;                              // Reset the counter
    currentChallenge = keccak256(nonce, currentChallenge, block.blockhash(block.number - 1));  // Save a hash that will be used as the next proof
    }
////////////////
// Events
////////////////

    event Payout(address indexed _from, address indexed _to, uint256 _amount);
}