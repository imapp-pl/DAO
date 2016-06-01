import "./DAO.sol";
import "./ManagedAccountEx.sol";

contract GolemOffer {

	uint totalCosts;
	uint dailyCosts;

	address 	contractor; // imapp
	bytes32 hashOfTerms;
	uint 	minDailyCosts;

	uint 	dateOfSignature;
	DAO 	client;		// addres of DAO

	ManagedAccountEx 	daoRewardAccount; // account used to manage the DAO reward

    bool public		contractOngoing;
	uint paidOut;

	function  GolemOffer( address _contractor, bytes32 _hashOfTerms, uint _totalCosts, uint _minDailyCosts ) {
		contractor 		= _contractor;
		hashOfTerms		= _hashOfTerms;
		totalCosts 		= _totalCosts;
		minDailyCosts	= _minDailyCosts;
		dailyCosts 		= _minDailyCosts;
	}

	//Called (supposedly) by The DAO to start cooperation
	function sign() {

		if( msg.value < totalCosts || dateOfSignature != 0 )
			throw;

		client 				= DAO( msg.sender );
		dateOfSignature		= now;
		contractOngoing		= true;

		daoRewardAccount	= new ManagedAccountEx( contractor );
	}

	//Called by the DAO to change min costs to some higher value
	function setDailyCosts(uint _dailyCosts) {

		if ( msg.sender != address(client) )
			throw;

		if( _dailyCosts < minDailyCosts )
			contractOngoing = false;

		dailyCosts = _dailyCosts;
	}

	//Called by the DAO to get pending payments and potentailly finish cooperation with this contractor/proposal
	function returnRemainingFunds() {
		if ( msg.sender != address(client) )
			throw;

		// Send back all unspent funds
		if( client.receiveEther.value(this.balance)() )
		{
			// I'm not sure what to do here. If the contract is broken then what should happen to the pending reward?
			// I'm leaving it commented as DAO can always call payDAOReward() before calling returnRemainingFunds()
			//payDAOReward();

			contractOngoing = false;
		}
	}

	//Called by the contractor to retrieve pending funds
	function getDailyPayment() {
		if(msg.sender != contractor)
			throw;

		uint amount = (now - dateOfSignature) / (1 days) * dailyCosts - paidOut;

		if( amount > 0 )
		{
			if(contractor.send(amount))
			{
				paidOut += amount;
			}
		}
	}

	// If contract is ongoing then only current DAO can change this addres, otherwice a contractor can do it
	function updateClientAddress( DAO _newClient )
	{
		if( contractOngoing ) {
			if( msg.sender != address(client) ) {
				throw;
			}
		} else if ( msg.sender != contractor ) {
			throw;
		}

		client 	= _newClient;
		// FIXME: daoRewardAccount.updateDAOAddress( address(_newClient) );
	}

	// Transfers pendingDAO reward to the DAO. Anyone can invoke this method
	function payPendingDAOReward 	() returns (bool)
	{
		if( msg.value > 0 )
			throw;

		if( contractOngoing )
		{
			return daoRewardAccount.payOutAll( client );
		}
		else
		{
			return false;
		}
	}
}
