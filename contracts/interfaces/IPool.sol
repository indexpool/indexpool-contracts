pragma solidity >=0.8.6;

import "../libraries/DataStructures.sol";

/**
 * @title Pool
 * @author IndexPool
 *
 * @notice Coordinates all index creation, deposits/withdrawals, and fee payments.
 *
 * @dev This contract has 3 main functions:
 *
 * 1. Create indexes
 * 2. Deposit / Withdrawals
 * 3. Control fees due to index creator and IndexPool protocol
 */

interface IPool {
    /**
     * @notice Counts how many indexes have been created.
     *
     * @dev Each index is appended into the `indexes` array, so to know how
     * many indexes have been created you only need to check its lenght.
     *
     */
    function getIndexesLength() external view returns (uint256);

    /**
     * @notice Lists all index creators.
     *
     * @dev Creator address is a part of the `Index` struct. So you just need
     * to iterate across indexes and pull the creator address.
     *
     */
    // TODO evaluate if this is being used somewhere.
    function getIndexesCreators() external view returns (address[] memory);

    /**
     * @notice List a user balance for a specific token in an specific index.
     *
     * @dev Access the mapping that control holdings for index -> token -> user.
     *
     * @param indexId Index Id (position in `indexes` array)
     * @param tokenAddress Token address
     * @param userAddress User address
     */
    function getTokenBalance(
        uint256 indexId,
        address tokenAddress,
        address userAddress
    ) external view returns (uint256);

    /**
     * @notice List allocation for tokens.
     *
     * @dev Simply access the `allocation` array in the Index struct, note that
     * order is the same as the `tokens` array.
     *
     * @param indexId Index Id (position in `indexes` array)
     */
    function getIndexAllocation(uint256 indexId)
    external
    view
    returns (uint256[] memory);

    /**
     * @notice List token addresses.
     *
     * @dev Simply access the `tokens` array in the Index struct.
     *
     * @param indexId Index Id (position in `indexes` array)
     */
    function getIndexTokens(uint256 indexId)
    external
    view
    returns (address[] memory);

    /**
     * @notice List allocation for tokens.
     *
     * @dev Uses a struct type called `OutputIndex` which is `Index` withouts
     * the mappings.
     *
     * @param indexId Index Id (position in `indexes` array)
     */
    function getIndex(uint256 indexId)
    external
    view
    returns (OutputIndex memory);

    /**
     * @notice Set max deposit (guarded launch).
     *
     * @dev Created to minimize damage in case any vulnerability is found on the
     * contract.
     *
     * @param newMaxDeposit Max deposit value in wei
     */
    function setMaxDeposit(uint256 newMaxDeposit)
    external;

    /**
     * @notice Creates a new index.
     *
     * @dev Create a new `Index` struct and append it to `indexes`.

     * Token addresses and allocations are set at this moment and will be
     * immutable for the rest of the contract's life.
     *
     * @param allocation Array of allocations (ordered by token addresses)
     * @param tokens Array of token addresses
     * @param paths Paths to be used respective to each token on DEX
     */
    function createIndex(
        address[] memory tokens,
        uint256[] memory allocation,
        address[][] memory paths
    ) external;

    /**
     * @notice Deposits ETH and use allocation data to split it between tokens.
     *
     * @dev Deposit basically registers how much of each token needs to be bought
     * according to the amount that was deposited.
     *
     * As per this current version no swaps are made at this point. There will need
     * to be an external call to a buy function in order to execute swaps.
     *
     * @param indexId Index Id (position in `indexes` array)
     * @param paths Paths to be used respective to each token on DEX
     */
    function deposit(uint256 indexId, address[][] memory paths)
    external
    payable;

    /**
     * @notice Withdraw tokens and convert them into ETH.
     *
     * @dev Withdraw basically registers how much of each token needs to be sold
     * according to the amounts that the user holds and the percentage he wants to
     * withdraw.
     *
     * @param indexId Index Id (position in `indexes` array)
     * @param sellPct Percentage of shares to be cashed out (1000 = 100%)
     * @param paths Execution paths
     */
    function withdraw(
        uint256 indexId,
        uint256 sellPct,
        address[][] memory paths
    ) external;

    /**
    * @notice Cash-out ERC20 tokens directly to wallet.
    *
    * @dev This is to be used whenever users want to cash out their ERC20 tokens.
    *
    * @param indexId Index Id (position in `indexes` array)
    * @param sharesPct Percentage of shares to be cashed out (1000 = 100%)
    */
    function cashOutERC20(uint256 indexId, uint256 sharesPct) external;

    /**
     * @notice Admin-force cash-out ERC20 tokens directly to wallet.
     *
     * @dev This is a security measure, basically giving us the ability to eject users
     * from the contract in case some vulnerability is found on the withdrawal method.
     *
     * @param indexId Index Id (position in `indexes` array)
     * @param sharesPct Percentage of shares to be cashed out (1000 = 100%)
     */
    function cashOutERC20Admin(
        address user,
        uint256 indexId,
        uint256 sharesPct
    ) external;

    /**
     * @notice Mint a specific NFT token.
     *
     * @dev Mints a specific NFT token remove assigned contracts from contract and into token.
     *
     * @param indexId Index Id (position in `indexes` array)
     * @param sharesPct Percentage of shares to be minted as NFT (1000 = 100%)
     */
    function mintPool721(
        uint256 indexId,
        uint256 sharesPct
    ) external;

    /**
     * @notice Burn a specific NFT token.
     *
     * @dev Burns a specific NFT token and assigns assets back to NFT owner.
     * Only callable by whoever holds the token.
     *
     * @param tokenId Token Id
     */
    function burnPool721(uint256 tokenId) external;

    /**
     * @notice Get Pool721 (NFT contract) address.
     *
     * @dev Get the address of the NFT contract minted by this Pool.
     */
    function getPool721Address() external view returns (address);

    /**
     * @notice Pay creator fee.
     *
     * @dev Only callable by the creator. Cashes out ETH funds that are due to
     * a 0.1% in all deposits on the created index.
     *
     * @param indexId Index Id (position in `indexes` array)
     */
    function payCreatorFee(uint256 indexId) external;

    /**
     * @notice Reads available  creator fee.
     *
     * @dev Check how much is owed to the creator.
     *
     * @param indexId Index Id (position in `indexes` array)
     */
    function getAvailableCreatorFee(uint256 indexId)
    external
    view
    returns (uint256);

    /**
     * @notice Pay protocol fee.
     *
     * @dev Only callable by the protocol creator. Cashes out ETH funds that are due to
     * a 0.1% in all deposits on the created index.
     *
     * @param indexId Index Id (position in `indexes` array)
     */
    function payProtocolFee(uint256 indexId) external;

    /**
     * @notice Reads available protocol fee.
     *
     * @dev Check how much is owed to the protocol.
     *
     * @param indexId Index Id (position in `indexes` array)
     */
    function getAvailableProtocolFee(uint256 indexId)
    external
    view
    returns (uint256);
}
