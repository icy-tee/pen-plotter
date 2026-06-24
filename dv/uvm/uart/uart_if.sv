// interface for agent so rx is write and tx is read from for tb
interface uart_if(input logic clk, input logic rst_n);
    logic rx;
    logic tx;
    clocking cb @(posedge clk); input rx; input tx; endclocking
    modport drv (output tx, input clk, rst_n);
    modport mon (clocking cb, input clk, rst_n);
endinterface
