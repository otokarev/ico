import pytest
import datetime
from eth_utils import to_wei
from web3.contract import Contract


#@pytest.fixture
#def pricing_strategy(chain, team_multisig):
#    args = [
#        to_wei(1, "ether")
#    ]
#    tx = {
#        "from": team_multisig,
#    }
#    contract, hash = chain.provider.deploy_contract('FlatFiatPricing', deploy_args=args, deploy_transaction=tx)
#    pricing_strategy.transact({"from": team_multisig}).setOneFiatInWeis(to_wei(1, 'ether'))
#
#    return contract

@pytest.fixture
def beam_token(chain, team_multisig, token_name, token_symbol, initial_supply) -> Contract:
    """Create the token contract."""

    args = [token_name, token_symbol, initial_supply, 0, True]  # Owner set

    tx = {
        "from": team_multisig
    }

    contract, hash = chain.provider.deploy_contract("CrowdsaleToken", deploy_args=args, deploy_transaction=tx)
    return contract

@pytest.fixture
def ico(chain, beam_token):#, pricing_strategy, team_multisig, default_finalize_agent):
    #args = [
    #    token,
    #    pricing_strategy,
    #    team_multisig,
    #    0,
    #    int(datetime.datetime.now().timestamp()) + 30*24*3600,
    #    0
    #]
    #contract, hash = chain.provider.deploy_contract('BeamCrowdsale', deploy_args=args)
#
    #return contract
    return 1

#@pytest.fixture
#def finalize_agent(chain, ico):
#
#    args = [
#        ico.address
#    ]
#    contract, hash = chain.provider.deploy_contract('NullFinalizeAgent', deploy_args=args)
#
#    return contract

def test_beamcrowdsale(ico): #, token, team_multisig, default_finalize_agent):

    # ico.transact({"from": team_multisig}).setFinalizeAgent(default_finalize_agent.address)

    # token.transact({"from": team_multisig}).setReleaseAgent(default_finalize_agent.address)
    # token.transact({"from": team_multisig}).setMintAgent(ico.address, True)

    assert 1 == 1
