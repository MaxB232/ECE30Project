// ========================================================================================
//     TEAM  INFO
// Group member 1 name: Max Bayer
// Group member 1 PID: A18238721
// Group member 2 name: Eduardo Hernandez
// Group member 2 PID: A16131979
// ========================================================================================

// ========================================================================================
// This is the data loading and memory allocation code. DO NOT MODIFY.
// You can edit or run your own test cases by modifying the .txt data files
// ========================================================================================
// Load the input arrays and parameters from the data file
LDA     X0, weights
LDA     X1, values
LDA     X2, n
LDUR    X2, [X2, #0]        // load n
LDA     X3, capacity
LDUR    X3, [X3, #0]        // load capacity

// Allocate the memo table and the selected array in the data segment.
// dynmem marks the first free word after the input data:
//   memo     = dynmem                                   ((n + 1) * (capacity + 1) words)
//   selected = dynmem + (n + 1) * (capacity + 1) * 8    (n words)
LDA     X4, dynmem          // memo starts at the first free word
ADDI    X9, X2, #1          // n + 1 rows
ADDI    X10, X3, #1         // capacity + 1 columns
MUL     X9, X9, X10         // number of memo entries
LSL     X9, X9, #3          // memo size in bytes
ADD     X5, X4, X9          // selected starts right after memo

        BL     runCargoSelection

        STOP

// ========================================================================================




////////////////////////////////
//                            //
//     runCargoSelection      //
//                            //
////////////////////////////////
runCargoSelection:
        // This function is provided. DO NOT MODIFY.
        //  Input:
        //  X0: The address of (pointer to) the weights array.
        //  X1: The address of (pointer to) the values array.
        //  X2: The number of items (n).
        //  X3: The capacity.
        //  X4: The address of (pointer to) the memo table.
        //  X5: The address of (pointer to) the selected array.
        //
        //  Output:
        //  X0: The maximum total value.
        //  Prints the maximum value, the selected array, and the selected item count.

        SUBI   SP, SP, #80
        STUR   FP, [SP, #0]
        STUR   LR, [SP, #8]
        STUR   X19, [SP, #16]
        STUR   X20, [SP, #24]
        STUR   X21, [SP, #32]
        STUR   X22, [SP, #40]
        STUR   X23, [SP, #48]
        STUR   X24, [SP, #56]
        STUR   X25, [SP, #64]
        STUR   X26, [SP, #72]
        ADDI   FP, SP, #72

        ADD    X19, X0, XZR       // weights
        ADD    X20, X1, XZR       // values
        ADD    X21, X2, XZR       // n
        ADD    X22, X3, XZR       // capacity
        ADD    X23, X4, XZR       // memo
        ADD    X24, X5, XZR       // selected
        ADDI   X25, X22, #1       // stride = capacity + 1

        // Initialize memo: row 0 and column 0 are 0, all other entries are -1
        ADDI   X9, XZR, #0        // i = 0
        ADD    X11, X23, XZR      // X11 = address of memo[0][0]
        SUBI   X13, XZR, #1       // X13 = -1 ("not computed" marker)
rcs_rowLoop:
        SUBS   XZR, X9, X21
        B.GT   rcs_initDone       // stop when i > n
        ADDI   X10, XZR, #0       // c = 0
rcs_colLoop:
        SUBS   XZR, X10, X22
        B.GT   rcs_rowDone        // stop when c > capacity
        ADD    X12, X13, XZR      // entry = -1 by default
        CBZ    X9, rcs_baseEntry  // row 0 is a base case
        CBNZ   X10, rcs_store     // column 0 is a base case
rcs_baseEntry:
        ADD    X12, XZR, XZR      // entry = 0 for base cases
rcs_store:
        STUR   X12, [X11, #0]     // memo[i][c] = entry
        ADDI   X11, X11, #8       // move to the next entry (row-major)
        ADDI   X10, X10, #1       // c++
        B      rcs_colLoop
rcs_rowDone:
        ADDI   X9, X9, #1         // i++
        B      rcs_rowLoop
rcs_initDone:

        // Clear the selected array
        ADDI   X9, XZR, #0        // j = 0
        ADD    X11, X24, XZR      // X11 = address of selected[0]
rcs_clearLoop:
        SUBS   XZR, X9, X21
        B.GE   rcs_clearDone      // stop when j >= n
        STUR   XZR, [X11, #0]     // selected[j] = 0
        ADDI   X11, X11, #8       // move to the next entry
        ADDI   X9, X9, #1         // j++
        B      rcs_clearLoop
rcs_clearDone:

        // best = solveKnapsack(weights, values, n, capacity, memo, stride)
        ADD    X0, X19, XZR
        ADD    X1, X20, XZR
        ADD    X2, X21, XZR
        ADD    X3, X22, XZR
        ADD    X4, X23, XZR
        ADD    X5, X25, XZR
        BL     solveKnapsack
        ADD    X26, X0, XZR       // keep best across the next call

        // count = recoverSelection(weights, values, n, capacity, memo, stride, selected)
        ADD    X0, X19, XZR
        ADD    X1, X20, XZR
        ADD    X2, X21, XZR
        ADD    X3, X22, XZR
        ADD    X4, X23, XZR
        ADD    X5, X25, XZR
        ADD    X6, X24, XZR
        BL     recoverSelection
        ADD    X25, X0, XZR       // keep the selected count (stride no longer needed)

        // Print the maximum value
        ADDI   X10, XZR, #10      // newline character
        ADDI   X11, XZR, #32      // space character
        PUTINT X26
        PUTCHAR X10

        // Print the selected array
        ADDI   X9, XZR, #0        // j = 0
        ADD    X12, X24, XZR      // address of selected[0]
rcs_printLoop:
        SUBS   XZR, X9, X21
        B.GE   rcs_printDone      // stop when j >= n
        LDUR   X13, [X12, #0]     // selected[j]
        PUTINT X13
        PUTCHAR X11
        ADDI   X12, X12, #8
        ADDI   X9, X9, #1         // j++
        B      rcs_printLoop
rcs_printDone:
        PUTCHAR X10

        // Print the selected item count
        PUTINT X25
        PUTCHAR X10

        ADD    X0, X26, XZR       // return the maximum value
        LDUR   X26, [SP, #72]
        LDUR   X25, [SP, #64]
        LDUR   X24, [SP, #56]
        LDUR   X23, [SP, #48]
        LDUR   X22, [SP, #40]
        LDUR   X21, [SP, #32]
        LDUR   X20, [SP, #24]
        LDUR   X19, [SP, #16]
        LDUR   LR, [SP, #8]
        LDUR   FP, [SP, #0]
        ADDI   SP, SP, #80
        BR     LR





////////////////////////////////
//                            //
//           max2             //
//                            //
////////////////////////////////
max2:
        //  Input:
        //  X0: The first value (a).
        //  X1: The second value (b).
        //
        //  Output:
        //  X0: The larger of a and b.

        //YOUR CODE STARTS HERE

        CMP X0, X1                //Compare X0 (a) and X1 (b) as signed values
        B.GT endmax2              //Branch to endmax2 if  a > b 
        ADD X0, X1, XZR           //else: Return b by copying it into X0
        
endmax2:BR     LR                 //Return to caller 


        //YOUR CODE ENDS HERE





////////////////////////////////
//                            //
//        getMemoAddr         //
//                            //
////////////////////////////////
getMemoAddr:
        //  Input:
        //  X0: The address of (pointer to) the memo table.
        //  X1: The number of available items i (row).
        //  X2: The remaining capacity (column).
        //  X3: The row stride of the memo table.
        //
        //  Output:
        //  X0: The address of the memo entry at (i, capacity).

        //YOUR CODE STARTS HERE

        MUL X4, X1, X3        //Entries before row i
        ADD X4, X4, X2        //Index of entry within entire table
        LSL X4, X4, #3        //Convert index to bytes (x8)
        ADD X0, X0, X4        //Save base + byte offset

        BR     LR             //Return to caller

        //YOUR CODE ENDS HERE





////////////////////////////////
//                            //
//       solveKnapsack        //
//                            //
////////////////////////////////
solveKnapsack:
        //  Input:
        //  X0: The address of (pointer to) the weights array.
        //  X1: The address of (pointer to) the values array.
        //  X2: The number of available items i.
        //  X3: The remaining capacity.
        //  X4: The address of (pointer to) the memo table.
        //  X5: The row stride of the memo table.
        //
        //  Output:
        //  X0: The maximum value F(i, capacity).

        //YOUR CODE STARTS HERE

        SUBI SP, SP, #96                //Make space for saved registers 
        STUR FP, [SP, #0]       //Save caller's frame pointer
        STUR LR, [SP, #8]       //Save return address
        STUR X19, [SP, #16]     //Save original X19 = Option 1 save
        STUR X20, [SP, #24]     //Save original X20
        STUR X21, [SP, #32]     //Save original X21
        STUR X22, [SP, #40]     //Save original X22
        STUR X23, [SP, #48]             //Save original X23
        STUR X24, [SP, #56]     //Save original X24
        STUR X25, [SP, #64]     //Save original X25
        STUR X26, [SP, #72]     //Save original X26 = for memo address table save
        ADDI FP, SP, #88                //Set frame pointer       

        ADD X20, X0, XZR        //Save The address of (pointer to) the weights array
        ADD X21, X1, XZR        //Save The address of (pointer to) the values array
        ADD X22, X2, XZR        //Save The number of available items i
        ADD X23, X3, XZR        //Save remaining capacity
        ADD X24, X4, XZR        //Save memo address
        ADD X25, X5, XZR        //Save row stride

                                        //Return Stored result if already computed
                                                //Setting up Parameters for getMemoAddr
        ADD X0, X24, XZR                // X0 = Memo addr
        ADD X1, X22, XZR                // X1 = # of available items i
        ADD X2, X23, XZR                // X2 = Remaining Capacity
        ADD X3, X25, XZR                // X3 = Row Stride

        BL getMemoAddr                  // Getting address of the memo entry at row i, column capacity
        ADD X26, X0, XZR                // Saving address into x26
        LDUR X0, [X26, #0]              // X0 = Getting value memo table
        ADDI X9, X0, #1                 // If X0 != -1 go to solveKnapsackEnd
        CBNZ X9, solveKnapsackEnd

                                        //Base Case: No items or no capacity
        ADD X0, XZR, XZR                // if ( i == 0 || capacity == 0) return 0
        CMPI X22, #0
        B.EQ solveKnapsackEnd
        CMPI X23, #0
        B.EQ solveKnapsackEnd 

                                        //Option 1: Exclude item i-1
                                                //Setting up params
                ADD X0, X20, XZR        
        ADD X1, X21, XZR       
        SUBI X2, X22, #1   
        ADD X3, X23, XZR    
        ADD X4, X24, XZR
        ADD X5, X25, XZR
        BL solveKnapsack        // Now X0 is set to the option 1's return
        ADD X19, X0, XZR        // X19 = skip


                                        //Option 2: Include item i-1, if it fits
// Not sure if I am using list correctly 
        SUBI X2, X22, #1        // x2 = i-1
        LSL X2, X2, #3          // X2 = off set (i-1)*8
        ADD X3, X20, XZR        // X3 becomes weights pointer
        ADD X3, X3, X2          // X3 = &weights[i-1]
        LDUR X1, [X3, #0]       // X1 = *weights[i-1]
        CMP X1, X23             // if *weights[i-1] <= capacity
        B.GT solveKnapsackSkip
                SUB X3, X23, X1         //Saving params
                ADD X0, X20, XZR        
                ADD X1, X21, XZR       
                SUBI X2, X22, #1       
                ADD X4, X24, XZR
                ADD X5, X25, XZR
                BL solveKnapsack        //Now X0 is set to the option 2's return
                                                   // calc value[i-1]
                SUBI X2, X22, #1        // x2 = i-1
                LSL X2, X2, #3          // X2 = off set (i-1)*8
                ADD X3, X21, XZR        // X3 = pointer to values list
                ADD X3, X3, X2          // X3 = &values[i-1]
                LDUR X1, [X3, #0]       // X1 = *values[i-1]

                                                //Setting up params for max2
                ADD X1, X0, X1          // X0 = take
                ADD X0, X19, XZR        // x1 = skip
                BL max2                         // X0 set to best
solveKnapsackSkip:      


solveKnapsackEnd:
                STUR X0, [X26, #0]  // Save best in *slot
                LDUR X26, [SP, #72]     //Restore original X26
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
        BR LR                                   //Return to caller
       
        //YOUR CODE ENDS HERE





////////////////////////////////
//                            //
//      recoverSelection      //
//                            //
////////////////////////////////
recoverSelection:
        //  Input:
        //  X0: The address of (pointer to) the weights array.
        //  X1: The address of (pointer to) the values array.
        //  X2: The number of items (n).
        //  X3: The capacity.
        //  X4: The address of (pointer to) the memo table.
        //  X5: The row stride of the memo table.
        //  X6: The address of (pointer to) the selected array (all zeros on entry).
        //
        //  Output:
        //  X0: The number of selected items.

        //YOUR CODE STARTS HERE

        SUBI SP, SP, #96  //Make space for saved registers and best
        STUR FP, [SP, #0]       //Save caller's frame pointer
        STUR LR, [SP, #8]       //Save return address
        STUR X19, [SP, #16]     //Save original X19
        STUR X20, [SP, #24]     //Save original X20
        STUR X21, [SP, #32]     //Save original X21
        STUR X22, [SP, #40]     //Save original X22
        STUR X23, [SP, #48]     //Save original X23
        STUR X24, [SP, #56]     //Save original X24
        STUR X25, [SP, #64]     //Save original X25
        STUR X26, [SP, #72]     //Save original X26
        ADDI FP, SP, #88        //Set frame pointer

        ADD X19, X0, XZR        //Save weights address
        ADD X20, X1, XZR        //Save values address
        ADD X21, X2, XZR        //Start i at n
        ADD X22, X3, XZR        //Save remaining capacity
        ADD X23, X4, XZR        //Save memo address
        ADD X24, X5, XZR        //Save row stride
        ADD X25, X6, XZR        //Save selected address
        ADD X26, XZR, XZR       //Start selectedCount at 0

recoverS_loop:
        CMP X21, XZR            //Compare i and 0
        B.LE recoverS_done      //End loop if i <= 0
        CMP X22, XZR            //Compare capacity and 0
        B.LE recoverS_done      //End loop if capacity <= 0

        ADD X0, X19, XZR        //Pass weights address
        ADD X1, X20, XZR        //Pass values address
        ADD X2, X21, XZR        //Pass current i
        ADD X3, X22, XZR        //Pass remaining capacity
        ADD X4, X23, XZR        //Pass memo address
        ADD X5, X24, XZR        //Pass row stride
        BL solveKnapsack        //Find best value with first i items
        STUR X0, [SP, #80]      //Save best before next call

        ADD X0, X19, XZR        //Pass weights address again
        ADD X1, X20, XZR        //Pass values address again
        SUBI X2, X21, #1        //Pass i-1 to skip current item
        ADD X3, X22, XZR        //Pass same remaining capacity
        ADD X4, X23, XZR        //Pass memo address again
        ADD X5, X24, XZR        //Pass same row stride
        BL solveKnapsack        //Find skip value; returned in X0

        LDUR X9, [SP, #80]      //Load saved best value
        CMP X9, X0              //Compare best and skip
        B.LE recoverS_next      //Skip item if best <= skip

        SUBI X9, X21, #1        //Index of current item
        LSL X9, X9, #3          //Convert index to bytes (x8)
        ADD X10, X25, X9        //Address of selected[i-1]
        ADDI X11, XZR, #1       //Set selection value to 1
        STUR X11, [X10, #0]     //Mark current item as selected

        ADD X10, X19, X9        //Address of weights[i-1]
        LDUR X11, [X10, #0]     //Load current item's weight
        SUB X22, X22, X11       //Subtract weight from capacity
        ADDI X26, X26, #1       //Increase selectedCount by 1

recoverS_next:
        SUBI X21, X21, #1       //Move to previous item
        B recoverS_loop         //Check loop conditions again

recoverS_done:
        ADD X0, X26, XZR        //Return selectedCount in X0

        LDUR X26, [SP, #72]     //Restore original X26
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
        BR LR           //Return to caller
