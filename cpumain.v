
module cpumain(display0, display1, display2, display3, display4, display5, display6, display7, clk, iobutton, iobutton2, pushbutton);

input iobutton, iobutton2, pushbutton;
output [6:0] display0;
output [6:0] display1;
output [6:0] display2;
output [6:0] display3;
output [6:0] display4;
output [6:0] display5;
output [6:0] display6;
output [6:0] display7;

input clk;


//memory map is defined here
localparam 	BEGINMEM=12'h000,
				ENDMEM=12'h0ff,
				CLKCOUNTER=16'h0d00,
				KEYPAD1=12'h0a00,
				KEYPAD2=12'h0a01,
				SEVENSEG=12'h0c00,
				SEVENSEG2=16'h0c01;


	
initial begin 
ss7 <= 16'h0000;
ss8 <= 16'h0000;
end	

// cpu's input-output pins
wire 	[15:0] pc,pc1;
reg 	[15:0] memory [0:127]; 
wire 	[15:0] data_out; 
reg	[15:0] data_in;
wire 	[11:0] address;
wire 	memwt;

// input-output devices
wire 	[15:0] datafrombutton;
wire 	[15:0] datafrombutton2;
reg 	[15:0] ss7;
reg   [15:0] ss8;
 
reg [25:0] clk1;
reg [15:0] clkcount;
 
always@(posedge clk)
begin
clk1 = clk1 + 1;
end

always@(posedge clk1[22])
begin
clkcount = clkcount + 1;
end
 
 
 
 
 
 
 
 
integer i;

//assign pc1=data_in;
//instantiation of cpu
cpu cpu1(.clk(clk), .outdata(pc), .data_out(data_out), .data_in(data_in), .address(address), .memwt(memwt));
//instantiation ofoutput device=  monitor
monitor monitor1( .display0(display0),.display1(display1),.display2(display2),.display3(display3),.display4(display4),.display5(display5),.display6(display6),.display7(display7), .info(ss7), .info2(ss8));
//instantiation of an input device =button
button button1(.iobutton(iobutton), .out(datafrombutton));
button2 button3(.iobutton2(iobutton2), .out2(datafrombutton2));
//multiplexer for cpu input
always @*  
		if ( (BEGINMEM<=address) && (address<=ENDMEM) )
			data_in=memory[address];
		else if ( (KEYPAD1==address) )
			data_in=datafrombutton;
		else if ( (KEYPAD2==address) )
			data_in=datafrombutton2;
		else if ( (CLKCOUNTER==address) )
		   data_in=clkcount;
		else
			data_in=16'hf345;	


always @(posedge clk) //data output port of the cpu
begin


if (memwt)
begin
if ( (BEGINMEM<=address) && (address<=ENDMEM) )
begin
memory[address]<=data_out;
end
else if ( SEVENSEG==address )
begin
ss7<= data_out;
end

else if ( SEVENSEG2==address)
begin
ss8 <= data_out;
end

end
end


initial begin
			$readmemh("RAM.txt", memory);
		  end

endmodule

module cpu( clk, outdata, data_out, data_in, address, memwt  );
 
 
                input clk;
                output reg [15:0] data_out;
               
               
 
                output  [15:0] outdata;//bunun bi manasi yok gibi duruyor
               
               
                input [15:0] data_in;
                output reg [11:0] address;
                output wire memwt;
               
                localparam          FETCH=4'b0000,
                                    LDI=4'b0001,
                                    LD=4'b0010,
                                    ST=4'b00011,
                                    JZ=4'b0100,
                                    JMP=4'b0101,
                                    ALU=4'b0111,
                                    PUSH=4'b1000,
                                    POP=4'b1001,
                                    POP1=4'b1110,
                                    CALL=4'b1010,
                                    RET=4'b1011,
                                    RET1=4'b1111,
                                    ADD = 3'b000,
                                    SUB = 3'b001,
                                    AND = 3'b010,
                                    OR =  3'b011,
                                    XOR = 3'b100,
                                    NOT = 3'b000,
                                    MOV = 3'b001,
                                    INC = 3'b010,
                                    DEC = 3'b011;
                                                                               
 
               
                reg [11:0] pc;
                reg [11:0] ir;
               
                reg [4:0] state;
                reg [15:0] regbank [7:0];
                reg [15:0] result;
               
                wire zeroresult;
               
                //assign outdata={memwt, 3'b0, address};
               
                assign outdata=regbank[1];
                //assign outdata=regbank[6];
 
 
                always @(posedge clk)
                                case(state)
                               
                                                FETCH:
                                                begin
                                                                state<=data_in[15:12];
                                                                ir<=data_in[11:0];
                                                                pc<=pc+1;
                                                end
 
                                                LDI:
                                                begin
                                                                state<=FETCH;
//                                                            regbank[ ir[2:0] ] <= memory[pc];
                                                                regbank[ ir[2:0] ] <= data_in;
                                                                pc<=pc+1;
                                                end
 
                                               
                                                LD:
                                                begin
                                                                state<=FETCH;
                                                                if (ir[2:0]!=3'h6)
//                                                              regbank[ir[2:0]] <= memory[regbank[ ir[5:3] ] [11:0]];
                                                                regbank[ir[2:0]] <= data_in;
                                                end
 
                                               
                                                ST:
                                                begin
                                                                state<=FETCH;
//                                                            memory[ regbank[ir[5:3]][11:0] ] <= regbank[ ir[8:6] ];
                                                end
               
 
               
                                                JZ:
                                                begin
                                                                if (regbank[6][0])
                                                                                pc <= pc+ir;                                        
                                                                state<=FETCH;
                                                end
               
 
               
                                                JMP:
                                                begin
                                                                pc <= pc+ir;                                        
                                                                state<=FETCH;
                                                end                                       
 
                                               
                                                ALU:
                                                begin                    
                                                                state<=FETCH;
                                                                regbank[ir[2:0]]<=result;
                                                                regbank[6][0]<=zeroresult;
                                                end
                                               
                                                PUSH:
                                                begin
                                                state <= FETCH;
                                                regbank[7] <= regbank[7]-1;
                                    end
                                               
                                                POP:
                                                begin
                                                regbank[7] <= regbank[7] + 1;
                                                state <= POP1;
                                                end
                                               
                                                POP1:
                                                begin
                                                state<=FETCH;
                                                regbank[ir[2:0]]<=data_in;
                                                end
                                               
                                                CALL:
                                                begin
                                                state<=FETCH;
                                                regbank[7]=regbank[7]-1;
                                                pc<=pc+ir;
                                               
                                                end
                                               
                                                RET:
                                                begin
                                                regbank[7] <= regbank[7] + 1;
                                                state <= RET1;
                                                end
                               
                                                RET1:
                                                begin
                                                pc<=data_in;
                                                state<=FETCH;
                                                end
                                               
                                               
                               
                endcase
                               
 
                always @*   //address bus of the cpu
                                case (state)
                                                FETCH: address=pc;
                                                LDI:   address=pc;
                                                LD:    address=regbank[ ir[5:3] ][11:0];
                                                ST:    address=regbank[ ir[5:3] ][11:0];
                                                PUSH:  address=regbank[7][11:0];
                                                POP:   address=regbank[7][11:0];
                                                CALL:  address=regbank[7][11:0];
                                                RET:   address=regbank[7][11:0];
                                                default: address=pc;
                                endcase
                                               
 
                always @*
                begin
                if(state==CALL)
                data_out = pc;
                else
                data_out = regbank[ ir[8:6] ];
                end
               
               
               
 
                assign memwt=(state==ST || state == PUSH || state == CALL);
                                               
                               
                always @*
                                                case (ir[11:9])
                                                ADD: result = regbank[ir[8:6]]+regbank[ir[5:3]];
                                                SUB: result = regbank[ir[8:6]]-regbank[ir[5:3]];
                                                AND: result = regbank[ir[8:6]]&regbank[ir[5:3]];
                                                OR: result = regbank[ir[8:6]]|regbank[ir[5:3]];
                                                XOR: result = regbank[ir[8:6]]^regbank[ir[5:3]];
                                                3'h7: case (ir[8:6])
                                                NOT: result = !regbank[ir[5:3]];
                                                MOV: result = regbank[ir[5:3]];
                                                INC: result = regbank[ir[5:3]]+1;
                                                DEC: result = regbank[ir[5:3]]-1;
                                                default: result=16'h0000;
                                endcase
                                                default: result=16'h0000;
                                endcase
                               
 
                assign zeroresult = ~|result;
 
                               
                initial begin
                                                state=FETCH;
                end                                                                                       
 
endmodule


module monitor( display0, display1, display2, display3, display4, display5, display6, display7, info, info2);

output reg [6:0] display0;
output reg [6:0] display1;
output reg [6:0] display2;
output reg [6:0] display3;
output reg [6:0] display4;
output reg [6:0] display5;
output reg [6:0] display6;
output reg [6:0] display7;


input [15:0] info;
input [15:0] info2;
reg [3:0] data [3:0];
reg [3:0] data2 [3:0];




always @*
begin
data[3]=info[15:12];
data[2]=info[11:8];
data[1]=info[7:4];
data[0]=info[3:0];
data2[0]=info2[3:0];
data2[1]=info2[7:4];
data2[2]=info2[11:8];
data2[3]=info2[15:12];
end


always@*
begin

case (data[0])
4'b0000: display0 = 7'b1000000; //0
4'b0001: display0 = 7'b1111001; 
4'b0010: display0 = 7'b0100100; 
4'b0011: display0 = 7'b0110000;
4'b0100: display0 = 7'b0011001; //4 
4'b0101: display0 = 7'b0010010; 
4'b0110: display0 = 7'b0000010; 
4'b0111: display0 = 7'b1111000; //7
4'b1000: display0 = 7'b0000000; 
4'b1001: display0 = 7'b0010000; //9
4'b1010: display0 = 7'b0100000; 
4'b1011: display0 = 7'b0000011; 
4'b1100: display0 = 7'b1000110; 
4'b1101: display0 = 7'b0100001; 
4'b1110: display0 = 7'b0000110; 
4'b1111: display0 = 7'b0001110; //f
endcase
end

always@*
begin
case (data[1])
4'b0000: display1 = 7'b1000000; //0
4'b0001: display1 = 7'b1111001; 
4'b0010: display1 = 7'b0100100; 
4'b0011: display1 = 7'b0110000;
4'b0100: display1 = 7'b0011001; //4 
4'b0101: display1 = 7'b0010010; 
4'b0110: display1 = 7'b0000010; 
4'b0111: display1 = 7'b1111000; //7
4'b1000: display1 = 7'b0000000; 
4'b1001: display1 = 7'b0010000; //9
4'b1010: display1 = 7'b0100000; 
4'b1011: display1 = 7'b0000011; 
4'b1100: display1 = 7'b1000110; 
4'b1101: display1 = 7'b0100001; 
4'b1110: display1 = 7'b0000110; 
4'b1111: display1 = 7'b0001110; //f
endcase
end

 always@*
begin
case (data[2])
4'b0000: display2 = 7'b1000000; //0
4'b0001: display2 = 7'b1111001; 
4'b0010: display2 = 7'b0100100; 
4'b0011: display2 = 7'b0110000;
4'b0100: display2 = 7'b0011001; //4 
4'b0101: display2 = 7'b0010010; 
4'b0110: display2 = 7'b0000010; 
4'b0111: display2 = 7'b1111000; //7
4'b1000: display2 = 7'b0000000; 
4'b1001: display2 = 7'b0010000; //9
4'b1010: display2 = 7'b0100000; 
4'b1011: display2 = 7'b0000011; 
4'b1100: display2 = 7'b1000110; 
4'b1101: display2 = 7'b0100001; 
4'b1110: display2 = 7'b0000110; 
4'b1111: display2 = 7'b0001110; //f
endcase
end

 always@*
begin
case (data[3])
4'b0000: display3 = 7'b1000000; //0
4'b0001: display3 = 7'b1111001; 
4'b0010: display3 = 7'b0100100;  
4'b0011: display3 = 7'b0110000;
4'b0100: display3 = 7'b0011001; //4 
4'b0101: display3 = 7'b0010010; 
4'b0110: display3 = 7'b0000010; 
4'b0111: display3 = 7'b1111000; //7
4'b1000: display3 = 7'b0000000; 
4'b1001: display3 = 7'b0010000; //9
4'b1010: display3 = 7'b0100000; 
4'b1011: display3 = 7'b0000011; 
4'b1100: display3 = 7'b1000110; 
4'b1101: display3 = 7'b0100001; 
4'b1110: display3 = 7'b0000110; 
4'b1111: display3 = 7'b0001110; //f
endcase
end

always@*
begin
case (data2[0])
4'b0000: display4 = 7'b1000000; //0
4'b0001: display4 = 7'b1111001; 
4'b0010: display4 = 7'b0100100; 
4'b0011: display4 = 7'b0110000;
4'b0100: display4 = 7'b0011001; //4 
4'b0101: display4 = 7'b0010010; 
4'b0110: display4 = 7'b0000010; 
4'b0111: display4 = 7'b1111000; //7
4'b1000: display4 = 7'b0000000; 
4'b1001: display4 = 7'b0010000; //9
4'b1010: display4 = 7'b0100000; 
4'b1011: display4 = 7'b0000011; 
4'b1100: display4 = 7'b1000110; 
4'b1101: display4 = 7'b0100001; 
4'b1110: display4 = 7'b0000110; 
4'b1111: display4 = 7'b0001110; //f
endcase
end

always@*
begin
case (data2[1])
4'b0000: display5 = 7'b1000000; //0
4'b0001: display5 = 7'b1111001; 
4'b0010: display5 = 7'b0100100; 
4'b0011: display5 = 7'b0110000;
4'b0100: display5 = 7'b0011001; //4 
4'b0101: display5 = 7'b0010010; 
4'b0110: display5 = 7'b0000010; 
4'b0111: display5 = 7'b1111000; //7
4'b1000: display5 = 7'b0000000; 
4'b1001: display5 = 7'b0010000; //9
4'b1010: display5 = 7'b0100000; 
4'b1011: display5 = 7'b0000011; 
4'b1100: display5 = 7'b1000110; 
4'b1101: display5 = 7'b0100001; 
4'b1110: display5 = 7'b0000110; 
4'b1111: display5 = 7'b0001110; //f
endcase
end

 always@*
begin
case (data2[2])
4'b0000: display6 = 7'b1000000; //0
4'b0001: display6 = 7'b1111001; 
4'b0010: display6 = 7'b0100100; 
4'b0011: display6 = 7'b0110000;
4'b0100: display6 = 7'b0011001; //4 
4'b0101: display6 = 7'b0010010; 
4'b0110: display6 = 7'b0000010; 
4'b0111: display6 = 7'b1111000; //7
4'b1000: display6 = 7'b0000000; 
4'b1001: display6 = 7'b0010000; //9
4'b1010: display6 = 7'b0100000; 
4'b1011: display6 = 7'b0000011; 
4'b1100: display6 = 7'b1000110; 
4'b1101: display6 = 7'b0100001; 
4'b1110: display6 = 7'b0000110; 
4'b1111: display6 = 7'b0001110; //f
endcase
end

 always@*
begin
case (data2[3])
4'b0000: display7 = 7'b1000000; //0
4'b0001: display7 = 7'b1111001; 
4'b0010: display7 = 7'b0100100;  
4'b0011: display7 = 7'b0110000;
4'b0100: display7 = 7'b0011001; //4 
4'b0101: display7 = 7'b0010010; 
4'b0110: display7 = 7'b0000010; 
4'b0111: display7 = 7'b1111000; //7
4'b1000: display7 = 7'b0000000; 
4'b1001: display7 = 7'b0010000; //9
4'b1010: display7 = 7'b0100000; 
4'b1011: display7 = 7'b0000011; 
4'b1100: display7 = 7'b1000110; 
4'b1101: display7 = 7'b0100001; 
4'b1110: display7 = 7'b0000110; 
4'b1111: display7 = 7'b0001110; //f
endcase

end

initial begin
data[0]=4'h8;
data[1]=4'h9;
data[2]=4'ha;
data[3]=4'hb;
end


endmodule	

module button(iobutton, out);
	input iobutton; //button input, coming from pin assignment 
	output reg [15:0] out; //16-bit data to be sent to cpu .Only bit 0 matters.
	
	always @*
		out[0]=~iobutton;

	initial begin
		out=16'h0000;
	end
endmodule


   module button2(iobutton2, out2);
	input iobutton2; //button input, coming from pin assignment 
	output reg [15:0] out2; //16-bit data to be sent to cpu .Only bit 0 matters.
	
	always @*
		out2[0]=~iobutton2;

	initial begin
		out2=16'h0000;
	end
endmodule