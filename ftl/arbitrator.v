module arbitrator(	
	//input
	reset,
	clk,	
	request0,
	release0,	
	request1,	
	release1,
	request2,	
	release2,
	request3,	
	release3,	
	request4,	
	release4,
	request5,	
	release5,
	//output
	permit0,
	permit1,
	permit2,
	permit3,
	permit4,
	permit5
	//state
	);

	input reset;
	input clk;	
	input request0;	
	input release0;	
	input request1;	
	input release1;	
	input request2;	
	input release2;
	input request3;	
	input release3;
	input request4;	
	input release4;
	input request5;	
	input release5;
	
	output permit0;
	output permit1;
	output permit2;
	output permit3;
	output permit4;
	output permit5;
	//output [3:0] state;
	
	reg permit0;
	reg permit1;
	reg permit2;
	reg permit3;	
	reg permit4;
	reg permit5;
	
	parameter REQUEST0	=4'b0000;
	parameter REQUEST1	=4'b0001;
	parameter REQUEST2	=4'b0010;
	parameter REQUEST3	=4'b0011;
	parameter REQUEST4	=4'b0100;
	parameter REQUEST5	=4'b0101;	
	parameter WAIT_RELEASE	=4'b0110;
	parameter WAIT_CYCLES 	=4'b0111;
	parameter FINISH      	=4'b1111;
	
	reg [3:0] state;
	reg [2:0] count;
	reg [3:0] index;
	
	always@ (posedge clk or negedge reset)
	begin
		if(!reset)
		begin
			state <= REQUEST0;
			permit0 <= 0;
			permit1 <= 0;
			permit2 <= 0;
			permit3 <= 0;
			permit4 <= 0;
			permit5 <= 0;
			index   <= 0;
			count	<=0;
		end
		else
		begin
			case (state) 
				REQUEST0:
				begin
					if(request0)
					begin
						permit0 <= 1;
						state <= WAIT_RELEASE;
						index <= REQUEST1;
					end
					else
					begin
						state <= REQUEST1;
					end
				end
				REQUEST1:
				begin
					if(request1)
					begin
						permit1 <= 1;
						state <= WAIT_RELEASE;
						index <= REQUEST2;
					end
					else
					begin
						state <= REQUEST2;
					end
				end
				REQUEST2:
				begin
					if(request2)
					begin
						permit2 <= 1;
						state <= WAIT_RELEASE;
						index <= REQUEST3;
					end
					else
					begin
						state <= REQUEST3;
					end
				end
				REQUEST3:
				begin
					if(request3)
					begin
						permit3 <= 1;
						state <= WAIT_RELEASE;
						index <= REQUEST4;
					end
					else
					begin
						state <= REQUEST4;
					end
				end
				REQUEST4:
				begin
					if(request4)
					begin
						permit4 <= 1;
						state <= WAIT_RELEASE;
						index <= REQUEST5;
					end
					else
					begin
						state <= REQUEST5;
					end
				end
				REQUEST5:
				begin
					if(request5)
					begin
						permit5 <= 1;
						state <= WAIT_RELEASE;
						index <= REQUEST0;
					end
					else
					begin
						state <= REQUEST0;
					end
				end
				WAIT_RELEASE:
				begin
					if(release0 | release1 | release2 | release3 | release4 | release5)
					begin						
						permit0 <= 0;
						permit1 <= 0;
						permit2 <= 0;
						permit3 <= 0;
						permit4 <= 0;
						permit5 <= 0;
						count <= 0;						
						state <= WAIT_CYCLES;
					end
					else
						state <= WAIT_RELEASE;
				end
				WAIT_CYCLES:
				begin
					if(count==4)
						state <= FINISH;
					else
						count <= count+1;
				end
				FINISH:
				begin
					state <= index;
				end
				default:state <= REQUEST0;
			endcase
		end
	end
endmodule
