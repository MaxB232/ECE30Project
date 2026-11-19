        //YOUR CODE STARTS HERE

	      SUBI SP, SP, #96	//Make space for saved registers and best
        STUR FP, [SP, #0]       //Save caller's frame pointer
        STUR LR, [SP, #8]       //Save return address
        STUR X19, [SP, #16]     //Save original X19
        STUR X20, [SP, #24]     //Save original X20
        STUR X21, [SP, #32]     //Save original X21
        STUR X22, [SP, #40]     //Save original X22
        STUR X23, [SP, #48]	//Save original X23
        STUR X24, [SP, #56]     //Save original X24
        STUR X25, [SP, #64]     //Save original X25
        STUR X26, [SP, #72]     //Save original X26
        ADDI FP, SP, #88        //Set frame pointer

        ADD X19, X0, XZR	//Save weights address
        ADD X20, X1, XZR        //Save values address
        ADD X21, X2, XZR        //Start i at n
        ADD X22, X3, XZR        //Save remaining capacity
        ADD X23, X4, XZR        //Save memo address
        ADD X24, X5, XZR        //Save row stride
        ADD X25, X6, XZR        //Save selected address
        ADD X26, XZR, XZR       //Start selectedCount at 0

recoverS_loop:
        CMP X21, XZR		//Compare i and 0
        B.LE recoverS_done      //End loop if i <= 0
        CMP X22, XZR            //Compare capacity and 0
        B.LE recoverS_done      //End loop if capacity <= 0

        ADD X0, X19, XZR	//Pass weights address
        ADD X1, X20, XZR        //Pass values address
        ADD X2, X21, XZR        //Pass current i
        ADD X3, X22, XZR        //Pass remaining capacity
        ADD X4, X23, XZR        //Pass memo address
        ADD X5, X24, XZR        //Pass row stride
        BL solveKnapsack        //Find best value with first i items
        STUR X0, [SP, #80]      //Save best before next call

        ADD X0, X19, XZR	//Pass weights address again
        ADD X1, X20, XZR        //Pass values address again
        SUBI X2, X21, #1        //Pass i-1 to skip current item
        ADD X3, X22, XZR        //Pass same remaining capacity
        ADD X4, X23, XZR        //Pass memo address again
        ADD X5, X24, XZR        //Pass same row stride
        BL solveKnapsack        //Find skip value; returned in X0

        LDUR X9, [SP, #80]	//Load saved best value
        CMP X9, X0              //Compare best and skip
        B.LE recoverS_next      //Skip item if best <= skip

        SUBI X9, X21, #1	//Index of current item
        LSL X9, X9, #3          //Convert index to bytes (x8)
        ADD X10, X25, X9        //Address of selected[i-1]
        ADDI X11, XZR, #1       //Set selection value to 1
        STUR X11, [X10, #0]     //Mark current item as selected

        ADD X10, X19, X9	//Address of weights[i-1]
        LDUR X11, [X10, #0]     //Load current item's weight
        SUB X22, X22, X11       //Subtract weight from capacity
        ADDI X26, X26, #1       //Increase selectedCount by 1

recoverS_next:
        SUBI X21, X21, #1	//Move to previous item
        B recoverS_loop         //Check loop conditions again

recoverS_done:
        ADD X0, X26, XZR	//Return selectedCount in X0

        LDUR X26, [SP, #72]	//Restore original X26
        LDUR X25, [SP, #64]     //Restore original X25
        LDUR X24, [SP, #56]     //Restore original X24
        LDUR X23, [SP, #48]     //Restore original X23
        LDUR X22, [SP, #40]     //Restore original X22
        LDUR X21, [SP, #32]     //Restore original X21
        LDUR X20, [SP, #24]     //Restore original X20
        LDUR X19, [SP, #16]     //Restore original X19
        LDUR LR, [SP, #8]       //Restore return address
        LDUR FP, [SP, #0]       //Restore caller's frame pointer
        ADDI SP, SP, #96        //Restore stack pointer
        BR LR		//Return to caller
