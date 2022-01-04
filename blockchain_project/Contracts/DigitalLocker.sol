pragma solidity ^0.4.20;

contract WorkbenchBase {
    event WorkbenchContractCreated(string applicationName, string workflowName, address originatingAddress);
    event WorkbenchContractUpdated(string applicationName, string workflowName, string action, address originatingAddress);

    string internal ApplicationName;
    string internal WorkflowName;

    function WorkbenchBase(string applicationName, string workflowName) internal {
        ApplicationName = applicationName;
        WorkflowName = workflowName;
    }

    function ContractCreated() internal {
        WorkbenchContractCreated(ApplicationName, WorkflowName, msg.sender);
    }

    function ContractUpdated(string action) internal {
        WorkbenchContractUpdated(ApplicationName, WorkflowName, action, msg.sender);
    }
}//metadata


contract DigitalLocker is WorkbenchBase('DigitalLocker', 'DigitalLocker')
{
    struct users  //Info of student
    {
        address acc; //account address
        string name;
        uint reg;
        bool present;
    }
    
    string constant LockerName='LIT DigitalLocker';
    enum StateType {AvailableToShare, SharingRequestPending, SharingWithThirdParty}
    address public contractOwner; //deployer(LIT)
    address[] public userAcc; //students of LIT
    mapping(address=>users) public userProfiles;
    mapping(address=>StateType) public State;
    mapping(address=>uint256) public expiryTime; //time when document requested
    function DigitalLocker()
    {
        contractOwner = msg.sender;  //LIT in our case
        ContractCreated();
    }
    
    function createUser(string Name,uint Reg)
    {
        if(contractOwner==msg.sender)
            revert();
        if(!userProfiles[msg.sender].present)
        {
            userProfiles[msg.sender].name=Name;
            userProfiles[msg.sender].reg=Reg;
            userProfiles[msg.sender].present=true;
            userAcc.push(msg.sender);
        }
    }
    function getAllUser() public returns(address[])
    {
        if(contractOwner!=msg.sender)
            revert();
        return userAcc;
    }
    
    function RequestLockerAccess(address user)
    {
        if(contractOwner != msg.sender)
            revert();
        expiryTime[user]=now + 60 minutes;
        State[user] = StateType.SharingRequestPending;
        ContractUpdated("RequestLockerAccess");
    }
    
    function serveSharingrequest()
    {
        if (contractOwner== msg.sender)
            revert();
        if(State[msg.sender]==StateType.SharingRequestPending)
        {
            State[msg.sender] = StateType.SharingWithThirdParty;
            ContractUpdated("ShareWithThirdParty");
        }
    }

    function ReleaseLockerAccess(address user)
    {
        if (contractOwner != msg.sender)
            revert();
        if(State[user]==StateType.SharingWithThirdParty)
        {
            State[user] = StateType.AvailableToShare;
            ContractUpdated("AvailableToShare");
        }
    }
    
    function RevokeAccessFromThirdParty() public
    {
        if (contractOwner == msg.sender && State[msg.sender]!=StateType.SharingWithThirdParty)
            revert();
        if(expiryTime[msg.sender]==now)
            State[msg.sender] = StateType.AvailableToShare;
    }
}