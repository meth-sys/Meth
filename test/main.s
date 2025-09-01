	.file	"main"
	.text
	.globl	print                           // -- Begin function print
	.p2align	2
	.type	print,@function
print:                                  // @print
	.cfi_startproc
// %bb.0:                               // %entry
	str	x30, [sp, #-16]!                // 8-byte Folded Spill
	.cfi_def_cfa_offset 16
	.cfi_offset w30, -16
	mov	x2, x1
	mov	x1, x0
	mov	w0, #1                          // =0x1
	bl	write
	ldr	x30, [sp], #16                  // 8-byte Folded Reload
	ret
.Lfunc_end0:
	.size	print, .Lfunc_end0-print
	.cfi_endproc
                                        // -- End function
	.globl	main                            // -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   // @main
	.cfi_startproc
// %bb.0:                               // %entry
	sub	sp, sp, #32
	.cfi_def_cfa_offset 32
	.cfi_offset w30, -16
	adrp	x0, .Lstr
	add	x0, x0, :lo12:.Lstr
	mov	w8, #5                          // =0x5
	mov	w1, #5                          // =0x5
	stp	x30, x0, [sp, #16]              // 8-byte Folded Spill
	str	x8, [sp, #8]
	bl	print
	ldr	x30, [sp, #16]                  // 8-byte Folded Reload
	mov	w0, wzr
	add	sp, sp, #32
	ret
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        // -- End function
	.type	.Lstr,@object                   // @str
	.section	.rodata,"a",@progbits
	.p2align	2, 0x0
.Lstr:
	.asciz	"Hello"
	.size	.Lstr, 6

	.section	".note.GNU-stack","",@progbits
