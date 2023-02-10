
# deps
update:; forge update
build  :; forge build
size  :; forge build --sizes

# storage inspection
inspect :; forge inspect ${contract} storage-layout --pretty

# local tests without fork
test  :; forge test
trace  :; forge test -vvv
gas  :; forge test --gas-report
test-contract  :; forge test --match-contract $(contract)
test-contract-gas  :; forge test --gas-report --match-contract ${contract}
trace-contract  :; forge test -vvv --match-contract $(contract)
test-test  :; forge test --match-test $(test)
trace-test  :; forge test --match-test $(test)
clean  :; forge clean
snapshot :; forge snapshot