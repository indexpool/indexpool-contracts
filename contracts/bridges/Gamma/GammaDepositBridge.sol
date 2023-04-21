// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IGammaDeposit.sol";
import "./interfaces/IHypervisorRouter.sol";
import "./interfaces/IHypervisor.sol";

contract GammaDepositBridge is IGammaDeposit {
    address constant hypervisorRouterAddress = 0xe0A61107E250f8B5B24bf272baBFCf638569830C;
    IHypervisorRouter constant hypervisorRouter = IHypervisorRouter(hypervisorRouterAddress);

    function deposit(
        address hypervisorAddress,
        address[] calldata tokens,
        uint256[] calldata percentages,
        uint256[4] calldata minAmountsin
    ) external override {
        uint256 numTokens = uint256(tokens.length);
        uint256[] memory amountsIn = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) { 
            amountsIn[i] = IERC20(tokens[i]).balanceOf(address(this)) * percentages[i] / 100_000;
            // Approve 0 first as a few ERC20 tokens are requiring this pattern.
            IERC20(tokens[i]).approve(hypervisorAddress, 0);
            IERC20(tokens[i]).approve(hypervisorAddress, amountsIn[i]);
        }     

        (uint256 depositA, uint256 depositB) = capRatios(tokens, amountsIn, hypervisorAddress);

        uint256 amountOut = hypervisorRouter.deposit(
            depositA,
            depositB,
            address(this),
            hypervisorAddress,
            minAmountsin
        );

        emit DEFIBASKET_GAMMA_DEPOSIT(amountsIn[0], amountsIn[1], amountOut);
    }

    function withdraw(
        address hypervisorAddress, 
        address[] calldata tokens,
        uint256 percentage,
        uint256[4] calldata minAmountsIn
    ) external override {
        IHypervisor hypervisor = IHypervisor(hypervisorAddress);

        uint256 amountIn = hypervisor.balanceOf(address(this)) * percentage / 100_000;

        (uint256 amountA, uint256 amountB) = hypervisor.withdraw(
            amountIn,
            address(this),
            address(this),
            minAmountsIn
        );

        emit DEFIBASKET_GAMMA_WITHDRAW(amountIn, amountA, amountB);
    }

    function capRatios( 
        address[] calldata tokens, 
        uint256[] memory amountsIn, 
        address hypervisorAddress
    ) internal view returns (uint256, uint256) {    
        (uint256 startA, uint256 endA) = hypervisorRouter.getDepositAmount(
            hypervisorAddress,
            tokens[0],
            amountsIn[0]            
        );

        (uint256 startB, uint256 endB) = hypervisorRouter.getDepositAmount(
            hypervisorAddress,
            tokens[1],
            amountsIn[1]            
        );              
       
        if (startB > amountsIn[0]) {
            return (amountsIn[0], endA);
        } 
        else if (startA > amountsIn[1]) {
            return (endB, amountsIn[1]);
        } 
        else {
            return (endB, endA);
        }        
    }    
}
