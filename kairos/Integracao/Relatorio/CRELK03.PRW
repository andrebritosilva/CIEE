#Include "Protheus.Ch" 

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CRELK03
Relatorio Fechamento de Caixa
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CRELK03()
Local titulo  := "Relatorio Fechamento de Caixa"
Local cDesc1  := "Este programa tem como objetivo imprimir relatorio "
Local cDesc2  := "de acordo com os parametros informados pelo usuario."
Local cDesc3  := "Relatorio Fechamento de Caixa"
Local nLin    := 80
Local Cabec1  := " Convenio  Local     Valor Bolsa        Valor CI       Juros   Descontos     Valor Total  Identificacao         Data Credito  Conta Corrente  RDR      Segmento  Tp Servico"
Local Cabec2  := ""

Private lAbortPrint := .F.
Private limite      := 132    //80 / 132 / 220 Colunas
Private tamanho     := "G"
Private nomeprog    := "CRELK03"
Private nTipo       := 18
Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey    := 0
Private m_pag       := 01
Private wnrel       := "CRELK03"
Private cString     := "ZCG"
Private cPerg       := "CRELK03   "
       

dbSelectArea("ZCG")
dbSetOrder(1)        

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,,.F.,Tamanho,,.F.)

pergunte(cperg,.F.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
   Return
Endif

nTipo := If(aReturn[4]==1,15,18)

Do Case
	Case cEmpant $ '01/02'
		Titulo := Alltrim(Titulo) + "  -  CIEE / SP"				
	Case cEmpant == '03'
		Titulo := Alltrim(Titulo) + "  -  CIEE / RJ"				
	Case cEmpant == '05'
		Titulo := Alltrim(Titulo) + "  -  CIEE / NACIONAL"						
EndCase		

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} RunReport
Rotina de processamento do relatório de Fechamento de Caixa
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)
Local _cSegmento	:= ""
Local _cTpservico	:= ""
Local _cCndQyr      := ""

If mv_par08 == 1 // Mista
	_cCndQyr += " AND ZCF_RMU = 'M'"
ElseIf mv_par08 == 2 // Privada
	_cCndQyr += " AND ZCF_RMU = 'R'"
ElseIf mv_par08 == 3 // Publica
	_cCndQyr += " AND ZCF_RMU = 'U'"
ElseIf mv_par08 == 4 // Outras Contribuicoes
	_cCndQyr += " AND ZCF_RMU = 'O'"
EndIf

If mv_par09 == 1 // Estagio
	_cCndQyr += " AND ZCF_TPSERV = 'E'"
ElseIf mv_par09 == 2 // Aprendiz Empregador
	_cCndQyr += " AND ZCF_TPSERV = 'AE'"
ElseIf mv_par09 == 3 // Outros Servicos
	_cCndQyr += " AND ZCF_TPSERV = 'OS'"
EndIf

if mv_par07 == 1 
	_cCndQyr += " ORDER BY ZCG_REGIST,ZCF_DTMOVI,ZCF_RMU, ZCF_TPSERV, ZCF_CODCTR "
Else
	_cCndQyr += " ORDER BY ZCG_REGIST,ZCF_DTMOVI,ZCF_TPSERV, ZCF_RMU, ZCF_CODCTR "
Endif

_cCndQyr:= "%"+_cCndQyr+"%"

BeginSql Alias "TMP"
	SELECT ZCF_CODCTR AS ZCG_CONV
		,ZCF_LOCCTR
		,ZCF_BA AS ZCG_BA
		,ZCF_CI AS ZCG_CI
		,0 AS ZCG_IR
		,ZCF_DESCON
		,(ZCF_BA+ZCF_CI) AS ZCG_VALOR
		,ZCF_DIDENT AS ZCG_IDENTD
		,ZCF_DTMOVI AS ZCG_EMISSA
		,ZCG_CONTA
		,ZCF_RDR AS ZCG_RDR
		,ZCF_RMU AS ZCG_RMU
		,ZCF_TPSERV AS ZCG_TPSERV  
		,ZCG_REGIST
	FROM %table:ZCF% ZCF
	INNER JOIN %table:ZCG% ZCG ON ZCG.D_E_L_E_T_=''
		AND ZCG_EMISSA BETWEEN %Exp:mv_par01% AND %Exp:mv_par02%
		AND ZCG_REGIST=ZCF_REGIST
	WHERE ZCF.D_E_L_E_T_ = ''
	AND ZCF_IDENT BETWEEN %Exp:mv_par03% AND %Exp:mv_par04%
	AND ZCF_RDR BETWEEN %Exp:mv_par05% AND %Exp:mv_par06%
	AND ZCF_FORPGT=%exp:mv_par10%
	AND ZCF_TIPO!='CRD'
	%EXP:_cCndQyr%
EndSql 

TcSetField("TMP","ZCG_EMISSA","D",8, 0 )

dbSelectArea("TMP")
dbGotop()

_cSegmento	:= TMP->ZCG_RMU
_cTpservico	:= TMP->ZCG_TPSERV

_nSub_BA	:= 0
_nSub_CI	:= 0
_nSub_JU	:= 0
_nSub_DC    := 0
_nSub_TO	:= 0
 
_nTot_BA	:= 0
_nTot_CI	:= 0
_nTot_JU	:= 0
_nTot_DC    := 0
_nTot_TO	:= 0

While !EOF()

   //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
   //³ Verifica o cancelamento pelo usuario...                             ³
   //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

   If lAbortPrint
      @ nLin, 000 PSAY "*** CANCELADO PELO OPERADOR ***"
      Exit
   Endif    

   //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
   //³ Impressao do cabecalho do relatorio. . .                            ³
   //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
              
   If nLin > 65 // Salto de Página. Neste caso o formulario tem 55 linhas...
      Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
      nLin := 8
   Endif

/*       1         2         3         4         5         6         7         8         9        10        11        12        13        14        15        16        17        18        19        20        21        22
1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
 Convenio  Local     Valor Bolsa        Valor CI       Juros     Valor Total  Identificacao         Data Credito  Conta Corrente  RDR      Segmento  Tp Servico
 999999    999999 999.999.999,99  999.999.999,99  999.999,99  999.999.999,99  xxxxxxxxxxxxxxxxxxxx  99/99/99      99999999-9      999999   xxxxxxxx  xxxxxxxxxx
*/
//TODO Substituir coluna Convenio por Contrato/Local
//TODO Incluir junto a coluna Juros a coluna Multa

//Quebra de linha
if mv_par07 == 1	     
	If _cSegmento <> TMP->ZCG_RMU
		nLin++
		@ nLin, 002 PSAY "SUB-TOTAL   ==>"
		@ nLin, 019 PSAY _nSub_BA		picture "@E 999,999,999.99"
		@ nLin, 035 PSAY _nSub_CI		picture "@E 999,999,999.99"
		@ nLin, 051 PSAY _nSub_JU		picture "@E 999,999.99"
		@ nLin, 063 PSAY _nSub_DC		picture "@E 999,999.99"
		@ nLin, 075 PSAY _nSub_TO		picture "@E 999,999,999.99"
		nLin++
		@ nLin, 000 PSAY __PrtThinLine()
		nLin++
	//	nLin++

		_cSegmento:= TMP->ZCG_RMU

	   _nSub_BA	:= 0
	   _nSub_CI	:= 0
	   _nSub_JU	:= 0
	   _nSub_DC := 0
	   _nSub_TO	:= 0
		
	EndIf
Else
	If _cTpservico <> TMP->ZCG_TPSERV
		nLin++
		@ nLin, 002 PSAY "SUB-TOTAL   ==>"
		@ nLin, 019 PSAY _nSub_BA		picture "@E 999,999,999.99"
		@ nLin, 035 PSAY _nSub_CI		picture "@E 999,999,999.99"
		@ nLin, 051 PSAY _nSub_JU		picture "@E 999,999.99"
		@ nLin, 063 PSAY _nSub_DC		picture "@E 999,999.99"
		@ nLin, 075 PSAY _nSub_TO		picture "@E 999,999,999.99"
		nLin++
		@ nLin, 000 PSAY __PrtThinLine()
		nLin++
	//	nLin++

		_cTpservico  := TMP->ZCG_TPSERV

	   _nSub_BA	:= 0
	   _nSub_CI	:= 0
	   _nSub_JU	:= 0
	   _nSub_DC := 0
	   _nSub_TO	:= 0
		
	EndIf	
Endif

@ nLin, 002 PSAY TMP->ZCG_CONV
@ nLin, 012 PSAY TMP->ZCF_LOCCTR
@ nLin, 019 PSAY TMP->ZCG_BA			picture "@E 999,999,999.99"
@ nLin, 035 PSAY TMP->ZCG_CI			picture "@E 999,999,999.99"
@ nLin, 051 PSAY TMP->ZCG_IR			picture "@E 999,999.99"
@ nLin, 063 PSAY TMP->ZCF_DESCON		picture "@E 999,999.99"
@ nLin, 075 PSAY TMP->ZCG_VALOR			picture "@E 999,999,999.99"
@ nLin, 091 PSAY TMP->ZCG_IDENTD
@ nLin, 113 PSAY TMP->ZCG_EMISSA
@ nLin, 127 PSAY TMP->ZCG_CONTA
@ nLin, 143 PSAY TMP->ZCG_RDR
@ nLin, 152 PSAY TMP->ZCG_RMU
@ nLin, 162 PSAY TMP->ZCG_TPSERV

nLin++
	
_nSub_BA	+= TMP->ZCG_BA
_nSub_CI	+= TMP->ZCG_CI
_nSub_JU	+= TMP->ZCG_IR
_nSub_DC    += TMP->ZCF_DESCON
_nSub_TO	+= TMP->ZCG_VALOR
   
_nTot_BA	+= TMP->ZCG_BA
_nTot_CI	+= TMP->ZCG_CI
_nTot_JU	+= TMP->ZCG_IR
_nTot_DC    += TMP->ZCF_DESCON
_nTot_TO	+= TMP->ZCG_VALOR

DbSelectArea("TMP")
	dbSkip() // Avanca o ponteiro do registro no arquivo
EndDo      

nLin++
@ nLin, 002 PSAY "SUB-TOTAL   ==>"
@ nLin, 019 PSAY _nSub_BA		picture "@E 999,999,999.99"
@ nLin, 035 PSAY _nSub_CI		picture "@E 999,999,999.99"
@ nLin, 051 PSAY _nSub_JU		picture "@E 999,999.99"
@ nLin, 063 PSAY _nSub_DC		picture "@E 999,999.99"
@ nLin, 075 PSAY _nSub_TO		picture "@E 999,999,999.99"
nLin++
@ nLin, 000 PSAY __PrtThinLine()

nLin++
@ nLin, 002 PSAY "TOTAL GERAL ==>"
@ nLin, 019 PSAY _nTot_BA		picture "@E 999,999,999.99"
@ nLin, 035 PSAY _nTot_CI		picture "@E 999,999,999.99"
@ nLin, 051 PSAY _nTot_JU		picture "@E 999,999.99"
@ nLin, 063 PSAY _nTot_DC		picture "@E 999,999.99"
@ nLin, 075 PSAY _nTot_TO		picture "@E 999,999,999.99"

DbSelectArea("TMP")
DbCloseArea()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza a execucao do relatorio...                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SET DEVICE TO SCREEN

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Se impressao em disco, chama o gerenciador de impressao...          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If aReturn[5]==1
   dbCommitAll()
   SET PRINTER TO
   OurSpool(wnrel)
Endif

MS_FLUSH()

Return
