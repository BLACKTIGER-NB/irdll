EXTERN	inputProc1ReturnAddress1	:	QWORD
EXTERN	inputProc1ReturnAddress2	:	QWORD
EXTERN	inputProc1CallAddress		:	QWORD
EXTERN	inputProc2ReturnAddress		:	QWORD

ESCAPE_SEQ_1	=	10h
ESCAPE_SEQ_2	=	11h
ESCAPE_SEQ_3	=	12h
ESCAPE_SEQ_4	=	13h
LOW_SHIFT		=	0Eh
HIGH_SHIFT		=	9h
SHIFT_2			=	LOW_SHIFT
SHIFT_3			=	900h
SHIFT_4			=	8F2h
NO_FONT			=	98Fh
NOT_DEF			=	2026h

.DATA
	inputProc1Var1	DB		03,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	inputProc1Tmp	DQ		0
	inputProc2Tmp	DQ		0
	inputProc2Tmp2	DQ		0

.CODE
inputProc1 PROC
	; eax�ɂ�IME����utf8�̕������n����Ă���
	mov		eax, dword ptr [rbp + 120h - 198h + 0Ch];
	; ah��0�ł����a-z�Ȃǂ�1byte�Ŏ��܂镶���Ȃ̂ŁA�ϊ������͕K�v�Ȃ�
	cmp		ah, 0;
	jnz		JMP_A;
	xor		bl, bl;

	; JMP_X,Y�ɂ��Ă̐����BMakeJMP�ŃR�[�h���j�󂳂�Ă��܂����߁A�������ۂ��ƃR�s�[���Ă��Ă���B
	; ������80h�Ɣ�r���Ă���̂�UTF8��U+0000 �c U+007F���ǂ����m�F���邽��
	; https://ja.wikipedia.org/wiki/UTF-8
	cmp		al, 80h;
	jnb		JMP_X;
	mov		ebx, eax;
	jmp     JMP_Y;

JMP_X:
	cmp		al, 0E0h;
	jnb		JMP_Y;
	movzx	ebx, byte ptr [rbp + 120h - 198h + 0Dh];
	and		bl, 3Fh;
	shl		al, 6;
	or		bl, al;

JMP_Y:
	push	inputProc1ReturnAddress1;
	ret;

JMP_A:
	lea		rcx,[rbp + 120h - 198h + 0Ch];
	call	inputProc1CallAddress;
	; �ϊ������G�X�P�[�v�ς݃e�L�X�g�A�h���X��ۑ��B 10 81 82�̂悤�ɂȂ�
	mov		inputProc2Tmp, rax;
	;�J�E���^�Ƃ��Ďg���̂ł��Ƃ��Ƃ��������͕̂ۑ�
	mov		inputProc1Tmp,rsi;
	xor		rsi,rsi;

JMP_B:
	; ���̂܂܃R�s�[����
	mov		rax, [r14];
	lea     rdx, [rsp+200h - 1D0h];
	xorps	xmm0, xmm0;
	mov		qword ptr [rsp+200h - 1D0h], 0;
	movdqu	xmmword ptr [rsp + 200h - 1C0h], xmm0;
	mov		rcx, r14;
	mov		dword ptr [rsp + 200h + 1C8h], edi;
	movdqa  xmm0, xmmword ptr [inputProc1Var1];
	movdqu  xmmword ptr [rsp + 200h - 198h], xmm0;

	; �Pbyte���o��
	mov		rbx, inputProc2Tmp;
	mov		bl, byte ptr [rbx + rsi];

	; null�����`�F�b�N
	cmp		bl,0;
	jz		JMP_C;

	mov		byte ptr [rsp + 200h - 1C4h], bl;
	mov		qword ptr [rsp + 200h - 1B0h], 0;
	mov		dword ptr [rsp + 200h - 1A8h], edi;
	mov		qword ptr [rsp + 200h - 1A0h], rdi;
	mov		dword ptr [rsp + 200h - 188h], edi;
	mov		dword ptr [rbp + 120h - 1A0h], 2;
	mov		word ptr [rbp + 120h - 1A0h + 4], di;
	mov		byte ptr [rbp + 120h - 1A0h + 6], 0;
	call	qword ptr [rax + 18h];

	; 1byte�i�߂�
	inc		rsi;
	jmp		JMP_B;

JMP_C:
	;�߂�
	mov		rsi, inputProc1Tmp;

	push	inputProc1ReturnAddress2;
	ret;
inputProc1 ENDP

;-------------------------------------------;

; ���L��qword ptr [rax+138h];�̊֐��i40 57 48 83 EC 20 48 8B 01 48 8B F9 48 8B 90 68 01 00 00�j���犄��o����
; rdi+54h : �L�����b�g�ʒu
; rdi+40h : �����񒷂�
; rdi+30h : ������A�h���X

inputProc2 PROC
	mov		inputProc2Tmp2,rsi; // �J�E���^�Ƃ��Ďg��
	xor		rsi,rsi; 

	mov		rcx, qword ptr [rdi + 40h];
	cmp		rcx, 10h;
	lea		rcx, [rdi + 30h];
	jbe		JMP_A;
	mov		rcx, [rcx];
	
JMP_A:
	movsxd	rax, dword ptr [rdi + 54h];
	sub		rax, 3;
	js		JMP_C;
	mov		al, byte ptr [rcx + rax];
	cmp		al, ESCAPE_SEQ_1;
	jz		JMP_B;
	cmp		al, ESCAPE_SEQ_2;
	jz		JMP_B;
	cmp		al, ESCAPE_SEQ_3;
	jz		JMP_B;
	cmp		al, ESCAPE_SEQ_4;
	jnz		JMP_C;

JMP_B:
	mov		rsi, 2;

JMP_C:
	mov		rax, qword ptr [rdi];
	mov		rcx, rdi;
	test	ebx, ebx;
	jz		JMP_D;
	call	qword ptr [rax+140h];
	jmp		JMP_E;

JMP_D:
	call	qword ptr [rax+138h];

JMP_E:
	cmp		rsi, 0;
	jz      JMP_F;
	dec		rsi;
	jmp		JMP_C;

JMP_F:
	mov		rsi,inputProc2Tmp2;

	push	inputProc2ReturnAddress;
	ret;
inputProc2 ENDP
END