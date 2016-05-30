import "./DAO.sol";

contract ManagedAccountExInterface {

	// restricts call to contractor
	modifier contractorOnly {}

	// contractor address (imapp)
	address public 	contractor;

	// total DAO reward sent to this account
	uint public 	accumulatedDAOReward;

	// Total Golem income
	uint public 	totalIncome;

	// The only method that can be used to transfer funds to this contract. Specifies total Golem income at this point
	function 	addFunds		( uint currentTotalIncome );

	// Tries to pay out specified amount of funds
	function 	payOut			( DAO dao, uint _amount ) contractorOnly external returns (bool);

	// Tries to pay out all funds
	function 	payOutAll		( DAO dao ) contractorOnly external returns (bool);

	// Sanity method
	function 	updateContractor ( address _newContractor ) contractorOnly;
}

// TODO: if necessary - implement fallback function to return funds by default
contract ManagedAccountEx is ManagedAccountExInterface {

	modifier contractorOnly {
		if( msg.sender != contractor )
		{
			throw;
		}

		_
	}

	function ManagedAccountEx( address _contractor )
	{
		contractor = _contractor;
	}

	// this can be sent from any source - we don't know at this point which contract will govern Golem transactions
	function 	addFunds	( uint currentTotalIncome )
	{
		// Makre sure that at leas some basic sanity checks are performed
		if( currentTotalIncome < ( msg.value + accumulatedDAOReward ) || currentTotalIncome < totalIncome || currentTotalIncome < totalIncome + msg.value )
			throw;

		totalIncome 			= currentTotalIncome;
		accumulatedDAOReward 	+= msg.value;
	}

	function 	payOut		( DAO dao, uint _amount ) contractorOnly external returns (bool)
	{
		if( this.balance < _amount )
			return false;

		// FIXME: is this the right way to call it (with '()')
		if( dao.DAOrewardAccount().call.value(_amount)() ) {
			return true;
		}
		else {
			throw;
		}
	}

	function 	payOutAll	( DAO dao ) contractorOnly external returns (bool)
	{
		// FIXME: is this the right way to call it (with '()')
		if( dao.DAOrewardAccount().call.value(this.balance)() ) {
			return true;
		}
		else {
			throw;
		}
	}

	function 	updateContractor ( address _newContractor ) contractorOnly
	{
		contractor = _newContractor;
	}
}
