#include "TOPCONN.ch"
#Include "Protheus.Ch" 

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CRELK01
Relatorio de Controle de Creditos Nao Identificados
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CRELK01()
Private cDesc1:= "Este programa tem como objetivo imprimir relatorio "
Private cDesc2:= "sobre Controle de Creditos Nao Identificados"
Private cDesc3:= "de acordo com os parametros informados pelo usuario."
Private titulo:= "Controle de Creditos Nao Identificados"
Private nLin  := 60
Private Cabec2:= "Data     | Tipo/Documento     | Depositante                    |          Valor | Documento       | No.  | Agencia                        | Identificacao |           B.A. |           C.I. |      Irregularidade | RDR          "
Private Cabec1:= "Banco Agencia Conta"
****          := "dd/mm/aa | tt-ttttttttttttttt | dddddddddddddddddddddddddddddd | vvvvvvvvvvvvvv | nnnnnnnnnnnnnnn | aaaa | aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa | ii-iiiiiiiiii | bbbbbbbbbbbbbb | cccccccccccccc | iiiiiiiiiiiiii s | rrrrrrrrrrr  "
****          := "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
****          := "0         1         2         3         4         5         6         7         8         9        10        11        12        13        14        15        16        17        18        19        20        21         "
****          := "0          11                   32                               65               82                100    107                              140             156              173              190            205 209
****          := "0        09                   30                               63               80                98     105                              138             154              171              188                207
****          := "00 09 11 30 32 63 65 80 82 98 100 105 107 138 140 154 156 171 173 188 190 205 207
Private imprime      := .T.
Private aOrd         := {}
Private lEnd         := .F.
Private lAbortPrint  := .F.
Private limite       := 220
Private tamanho      := "G"
Private nomeprog     := StrTran(FunName(), "#", "")
Private nTipo        := 15
Private aReturn      := { "Zebrado", 1, "Administracao", 1, 2, 1, "", 1}
Private nLastKey     := 0
Private cbtxt        := Space(10)
Private cbcont       := 00
Private CONTFL       := 01
Private m_pag        := 01
Private wnrel        := "CRELK01" // Coloque aqui o nome do arquivo usado para impressao em disco
Private cString      := "SZ5"
Private cPerg        := "CFINR68"
Private _nFL         := 0
Private _cUseFech  	:= Alltrim(GetMv("CI_USEFECH"))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ mv_par01 - Conta de                                    ³
//³ mv_par02 - Conta ate                                   ³
//³ mv_par03 - Emissao de                                  ³
//³ mv_par04 - Emissao ate                                 ³
//³ mv_par05 - Depositante                                 ³
//³ mv_par08 - Identificacao de                            ³
//³ mv_par09 - Identificacao ate                           ³
//³ mv_par08 - RDR de                                      ³
//³ mv_par09 - RDR ate                                     ³
//³ mv_par10 - Status Aberto/Fechado/Todos                 ³
//³ mv_par11 - Irregularidade Com/Sem/Todos                ³
//³ mv_par12 - Status Aberto/Fechado/Todos                 ³
//³ mv_par13 - Tipo Irregular de                           ³
//³ mv_par14 - Tipo Irregular ate                          ³
//³ mv_par15 - Fechamento                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Pergunte(cPerg, .F.)   

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.T.,Tamanho,,.F.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

nTipo := If(aReturn[4]==1,15,18)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

RptStatus({|| CCK09RUN(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK09RUN
Rotina de processamento do relatorio
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CCK09RUN(Cabec1,Cabec2,Titulo,nLin)
Local _cCndQyr := ""

If !Empty(mv_par05)								
	_cCndQyr += " AND ZCG_DEPOS = '"+mv_par05+"'"
EndIf

If mv_par10 == 1
	_cCndQyr += " AND ZCF_RDR     = '' "
ElseIf mv_par10 == 2
	_cCndQyr += " AND ZCF_RDR    <> '' "
EndIf

If mv_par11 == 1
	_cCndQyr += " AND ZCG_IR     <> 0 "
ElseIf mv_par11 == 2
	_cCndQyr += " AND ZCG_IR      = 0 "
EndIf

If mv_par12 == 1
	_cCndQyr += " AND ZCG_IRRDR   = '' "
ElseIf mv_par12 == 2
	_cCndQyr += " AND ZCG_IRRDR  <> '' "
EndIf

_cCndQyr += " AND    ZCG_IRTIP BETWEEN '"+mv_par13+"' AND '"+mv_par14+"' "

_cCndQyr += " 	ORDER BY ZCG_FILIAL,ZCG_CONTA,ZCG_BANCO,ZCG_AGENCI,ZCG_EMISSA,ZCG_VALOR "

_cCndQyr:= "%"+_cCndQyr+"%"

BeginSql Alias "QUERY"
	SELECT ZCG_BANCO
		  ,ZCG_AGENCI
		  ,ZCG_CONTA
		  ,ZCG_EMISSA
		  ,ZCG_TIPO
		  ,ZCG_DEPOS
		  ,(ZCF_BA+ZCF_CI) AS ZCG_VALOR
		  ,ZCG_NDOC
		  ,ZCG_NAGE
		  ,ZCF_IDENT AS ZCG_IDENT
		  ,ZCF_BA AS ZCG_BA
		  ,ZCF_CI AS ZCG_CI
		  ,ZCF_RDR AS ZCG_RDR
		  ,ZCG_IR
		  ,ZCG_IRTIP
		  ,ZCG_IRRDR
		  ,ZCG.R_E_C_N_O_ REGZCG
	FROM %table:ZCF% ZCF
	INNER JOIN %table:ZCG% ZCG ON ZCG_FILIAL=%xFilial:ZCG% AND ZCG.D_E_L_E_T_=''
		AND ZCG_CONTA BETWEEN %Exp:mv_par01% AND %Exp:mv_par02%
		AND ZCG_EMISSA BETWEEN %Exp:mv_par03% AND %Exp:mv_par04%
		AND ZCG_REGIST=ZCF_REGIST
	WHERE ZCF.D_E_L_E_T_ = ''
	AND ZCF_IDENT BETWEEN %Exp:mv_par06% AND %Exp:mv_par07%
	AND ZCF_RDR BETWEEN %Exp:mv_par08% AND %Exp:mv_par09%
	AND ZCF_TIPO!='CRD'
	%EXP:_cCndQyr%
EndSql 


TCSETFIELD("QUERY","ZCG_EMISSA","D")

dbSelectArea("QUERY")
dbGoTop()

nLin       := 60


While !EOF()
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	
	Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " +QUERY->ZCG_CONTA
	Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	nLin := 9
	
	_cBanco      := QUERY->ZCG_BANCO
	_cAgencia    := QUERY->ZCG_AGENCI
	_cConta      := QUERY->ZCG_CONTA
	
	_nDia_V := 0
	_nDia_B := 0
	_nDia_C := 0
	_nDia_I := 0
	
	_nBco_V := 0
	_nBco_B := 0
	_nBco_C := 0
	_nBco_I := 0
	
	While !EOF() .And. 	_cConta+_cBanco+_cAgencia == QUERY->ZCG_CONTA+QUERY->ZCG_BANCO+QUERY->ZCG_AGENCI
		
		If nLin > 55 // Salto de Página. Neste caso o formulario tem 55 linhas...
			Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " +QUERY->ZCG_CONTA
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 9
		Endif
		
		_dEmissao   := DTOS(QUERY->ZCG_EMISSA)
		_dEmis      := QUERY->ZCG_EMISSA
		
		_nDia_V := 0
		_nDia_B := 0
		_nDia_C := 0
		_nDia_I := 0		
		
		While !EOF() .And. 	_cConta+_cBanco+_cAgencia+_dEmissao == QUERY->ZCG_CONTA+QUERY->ZCG_BANCO+QUERY->ZCG_AGENCI+DTOS(QUERY->ZCG_EMISSA)
			
			If nLin > 55 // Salto de Página. Neste caso o formulario tem 55 linhas...
				Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " +QUERY->ZCG_CONTA
				Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
				nLin := 9
			Endif
			
			@ nLin, 000 PSay QUERY->ZCG_EMISSA
			@ nLin, 009 PSay "|"
			@ nLin, 011 PSay QUERY->ZCG_TIPO+"-"+LEFT(POSICIONE("SZ9",2,xFilial("SZ9")+QUERY->ZCG_TIPO,"Z9_TIPO_D"),15)
			@ nLin, 030 PSay "|"
			@ nLin, 032 PSay LEFT(QUERY->ZCG_DEPOS,25)
			@ nLin, 063 PSay "|"
			@ nLin, 065 PSay QUERY->ZCG_VALOR Picture "@E 999,999,999.99"
			@ nLin, 080 PSay "|"
			@ nLin, 082 PSay QUERY->ZCG_NDOC
			@ nLin, 098 PSay "|"
			@ nLin, 100 PSay QUERY->ZCG_NAGE
			@ nLin, 105 PSay "|"
			@ nLin, 107 PSay POSICIONE("SZA",1,xFilial("SZA")+QUERY->ZCG_NAGE,"ZA_NAGE_D")
			@ nLin, 138 PSay "|"
			@ nLin, 140 PSay QUERY->ZCG_IDENT+"-"+LEFT(POSICIONE("SZB",1,xFilial("SZB")+QUERY->ZCG_IDENT,"ZB_IDENT_D"),10)
			@ nLin, 154 PSay "|"
			@ nLin, 156 PSay QUERY->ZCG_BA Picture "@E 999,999,999.99"
			@ nLin, 171 PSay "|"
			@ nLin, 173 PSay QUERY->ZCG_CI Picture "@E 999,999,999.99"
			@ nLin, 188 PSay "|"
			@ nLin, 190 PSay QUERY->ZCG_IR Picture "@E 999,999,999.99"
			@ nLin, 210 PSay "|"
			@ nLin, 212 PSay QUERY->ZCG_RDR
			
			If mv_par11<>2 .And. QUERY->ZCG_IR<>0
				nLin ++                         
    			@ nLin, 188 PSay "|"
	    		@ nLin, 190 PSay QUERY->ZCG_IR Picture "@E 999,999,999.99"
			    If QUERY->ZCG_IRTIP == "B"
			      @ nLin, 205 PSay "B.A."
			    ElseIf QUERY->ZCG_IRTIP == "C"  
			      @ nLin, 205 PSay "C.I."
			    ElseIf QUERY->ZCG_IRTIP == "D"
			      @ nLin, 205 PSay "Dev."
 		        EndIf  			      
 		        @ nLin, 210 PSay "|"
	    		@ nLin, 212 PSay QUERY->ZCG_IRRDR

				nLin ++	    		
	    	EndIf	
			
			_nDia_V := _nDia_V + QUERY->ZCG_VALOR
			_nDia_B := _nDia_B + QUERY->ZCG_BA
			_nDia_C := _nDia_C + QUERY->ZCG_CI
			_nDia_I := _nDia_I + QUERY->ZCG_IR
						
			_nBco_V := _nBco_V + QUERY->ZCG_VALOR
			_nBco_B := _nBco_B + QUERY->ZCG_BA
			_nBco_C := _nBco_C + QUERY->ZCG_CI
			_nBco_I := _nBco_I + QUERY->ZCG_IR			


            dbSelectArea("ZCG")
            DbGoTo(QUERY->REGZCG)
   			RecLock("ZCG", .F.) 
   			  If mv_par15 == 1
   			     _cAux := "S" 
   			  Else
//   			     If AllTrim(SubStr(cUsuario,7,11)) $ _cUseFech // "Siga/Jurandir/Luis Carlos/Adilson" .And. mv_par15 == 3 // alterado pelo cg no dia 15/08 conf. chamado 11323
   			     If AllTrim(cUserName) $ _cUseFech // "Siga/Jurandir/Luis Carlos/Adilson" .And. mv_par15 == 3 // alterado pelo cg no dia 15/08 conf. chamado 11323
   			       _cAux := " "
   			     Else
   			       _cAux := ZCG->ZCG_FECHA
   			     EndIf
   			  EndIf 
			   ZCG->ZCG_FECHA := _cAux
			msUnLock()

			
			dbSelectArea("QUERY")
			dbSkip()
			nLin ++
		EndDo
		
		nLin ++
		@ nLin, 000 PSay "Total Dia: "
		@ nLin, 011 PSay _dEmis
		@ nLin, 063 PSay "|"
		@ nLin, 065 PSay _nDia_V Picture "@E 999,999,999.99"
		@ nLin, 080 PSay "|"
		@ nLin, 154 PSay "|"
		@ nLin, 156 PSay _nDia_B Picture "@E 999,999,999.99"
		@ nLin, 171 PSay "|"
		@ nLin, 173 PSay _nDia_C Picture "@E 999,999,999.99"
		@ nLin, 188 PSay "|"
		@ nLin, 190 PSay _nDia_I Picture "@E 999,999,999.99"
		@ nLin, 210 PSay "|"

		nLin ++
		nLin ++		
		nLin ++		
	EndDo
	
	nLin ++
	@ nLin, 000 PSay "Total Banco: "+_cBanco+"-"+_cAgencia+"/"+_cConta
	@ nLin, 063 PSay "|"
	@ nLin, 065 PSay _nBco_V Picture "@E 999,999,999.99"
	@ nLin, 080 PSay "|"
	@ nLin, 154 PSay "|"
	@ nLin, 156 PSay _nBco_B Picture "@E 999,999,999.99"
	@ nLin, 171 PSay "|"
	@ nLin, 173 PSay _nBco_C Picture "@E 999,999,999.99"
	@ nLin, 188 PSay "|"
    @ nLin, 190 PSay _nBco_I Picture "@E 999,999,999.99"
	@ nLin, 210 PSay "|"
	nLin ++
	
		
EndDo

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza a execucao do relatorio...                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("QUERY")
dbCloseArea()

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