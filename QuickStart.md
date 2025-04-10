# Quick Start Guide

This is a quick start guide to use the sample solution given here. Follow these steps to get the signal processing working:

## Setup

- Start the AWG and the PC in the correct order. Make sure a DC-Block is connected to the AWG output to prevent damage by reflected signals. Always use the ESD protection if you work with the AWG

- Connect the AWG to the RTO for trigger: SAMPLE MRK OUT -> RTO CH4

- AWG loses external clock, therefore use internal clock or fix the issue. For external clock use AWG's REF CLK IN for external clock source, e.g. RTO's REF OUT on the back. Change code in main to use external clock 

- Connect AWG output to radar hardware. Use DIRECT OUT (with DC-Block) or change the code and use AMP OUT (with DC-Block)

- Connect radar hardware to RTO CH1 to acquire IF signal

## Code

- Open main.m in code directory

- Go back to main directory and run init to add all necessary folders to the MATLAB path

- Stay in main directory (you see all folders, the init.m, the Readme, ...) during measurement, otherwise code won't find iqtools

- Setup radar parameters, be aware of the cfg.multiply factor if a "Frequenzdoppler" is used in hardware. If needed change AWG and RTO settings in the cfg struct

- Run code and watch console for information output 

- Stop measurement always by pressing on the button in the generated figure. With this AWG and RTO will be disconnected from the PC and you can run the code again

- Best troubleshooting is to restart AWG and PC in the correct order and to hit PRESET on the RTO

