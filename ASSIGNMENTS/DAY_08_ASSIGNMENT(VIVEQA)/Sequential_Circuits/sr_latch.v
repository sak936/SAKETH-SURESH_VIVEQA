module sr_latch(S,R,Q,Qbar);
input S,R;
output Q,Qbar;

nor nor1(Q,R,Qbar);
nor nor2(Qbar,S,Q);

endmodule