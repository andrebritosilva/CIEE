#Include 'Protheus.ch'
#Include 'Topconn.ch'
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CRELK04
Relatorio de Controle de Creditos Nao Identificados
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CRELK04()
Private cDesc1 := "Este programa tem como objetivo imprimir relatorio "
Private cDesc2 := "sobre Controle de Creditos Nao Identificados"
Private cDesc3 := "de acordo com os parametros informados pelo usuario."
Private titulo := "Controle de Creditos Nao Identificados"
Private nLin   := 80

//Private Cabec2:= "Data     | Tipo/Documento         | Depositante                    |          Valor | Documento       | No.  | Agencia                        | Identificacao |           B.A. |           C.I. |  Irregularidade | RDR          "
Private Cabec2:= "Data     | Tipo/Documento         | Depositante                              |          Valor | Documento       | Unid | Contrato               | Identificacao |           B.A. |           C.I. |  Irregularidade | RDR          "
Private Cabec1:= "Banco Agencia Conta"
****          := "dd/mm/aa | tt-ttttttttttttttt | dddddddddddddddddddddddddddddd | vvvvvvvvvvvvvv | nnnnnnnnnnnnnnn | aaaa | aaa                                                                                                          aaaaaaaaaaaaaaaaaaaaaaaaaaa | ii-iiiiiiiiii | bbbbbbbbbbbbbb | cccccccccccccc | iiiiiiiiiiiiii s | rrrrrrrrrrr  "
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
Private wnrel        := "CFINR05" // Coloque aqui o nome do arquivo usado para impressao em disco
Private cString      := "SZ5"
Private cPerg        := "CFINR05"
Private _nFL         := 0


Pergunte(cPerg, .F.)

//wnrel := SetPrint(cString,NomeProg,"",@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.F.,Tamanho,,.T.)
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

Do Case
	Case cEmpant $ '01/02'
		Titulo := Alltrim(Titulo) + " CIEE / SP"				
		If mv_par15 == 1
			titulo := titulo + " - Fluxo"
		ElseIf mv_par15 == 2
			titulo := titulo + " - Não Fluxo"
		EndIf  		
	Case cEmpant == '03'
		Titulo := Alltrim(Titulo) + " CIEE / RJ"				
		If mv_par15 == 1
			titulo := titulo + " - Fluxo"
		ElseIf mv_par15 == 2
			titulo := titulo + " - Não Fluxo"
		EndIf  				
	Case cEmpant == '05'
		Titulo := Alltrim(Titulo) + " CIEE / NACIONAL"						
		If mv_par15 == 1
			titulo := titulo + " - Fluxo"
		ElseIf mv_par15 == 2
			titulo := titulo + " - Não Fluxo"
		EndIf  				
EndCase	

RptStatus({|| CRK04RUN(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CRK04RUN
Rotina de processamento do relatorio
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CRK04RUN(Cabec1,Cabec2,Titulo,nLin)
Local _nBcoG_V := 0
Local _nBcoG_B := 0
Local _nBcoG_C := 0
Local _nBcoG_I := 0
Local _nContCre:= 0
Local _cCndQyr := ""
Local lZCF     := .F.

If mv_par05 == 1								
	_cCndQyr += " AND ZCG_DEPOS <> '' "
ElseIf mv_par05 == 2
	_cCndQyr += " AND ZCG_DEPOS = '' "
EndIf

If mv_par10 == 1 						//aberto
	_cCndQyr += " AND ZCF_RDR     = '' "
ElseIf mv_par10 == 2 					//fechado
	_cCndQyr += " AND ZCF_RDR    <> '' "
ElseIf mv_par10 == 3 					//ambos
	If mv_PAR16 == 1 					//SIM
		_cCndQyr += " AND (ZCF_RDR = '' OR ((ZCF_RDR <> '' AND ZCG_FECRAT = '') AND (SUBSTRING(ZCF_RDR,1,2) <> 'AP'))) " //status (Sempre em aberto)
	Elseif mv_PAR16 == 2 				//NAO
		_cCndQyr += " AND ZCF_RDR = '' " //status (Sempre em aberto)
	EndIf
EndIf

If mv_par11 == 1
	_cCndQyr += " AND ZCG_IR <> 0 "
ElseIf mv_par11 == 2
	_cCndQyr += " AND ZCG_IR = 0 "
EndIf

If mv_par12 == 1
	_cCndQyr += " AND ZCG_IRRDR = '' "
ElseIf mv_par12 == 2
	_cCndQyr += " AND ZCG_IRRDR <> '' "
EndIf

_cCndQyr += " AND    ZCG_IRTIP BETWEEN '"+mv_par13+"' AND '"+mv_par14+"' "

If mv_par15 == 1
	_cCndQyr += " AND ZCG_FLUXO   = 'S' "
ElseIf mv_par15 == 2
	_cCndQyr += " AND ZCG_FLUXO   = ''  "
EndIf

_cCndQyr += " ORDER BY ZCG_FILIAL,ZCG_CONTA,ZCG_BANCO,ZCG_AGENCI,ZCG_EMISSA,ZCG_VALOR "
_cCndQyr:= "%"+_cCndQyr+"%"

BeginSql Alias "QUERY"
	SELECT ZCG_BANCO
		,ZCG_AGENCI
		,ZCG_CONTA
		,ZCG_CONVEN
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
		,ZCG_HIST
		,ZCG_IMPFLG
		,ZCG_UNIDAD
		,ZCG_CONV
	FROM %table:ZCF% ZCF
	INNER JOIN %table:ZCG% ZCG ON ZCG_FILIAL=%xFilial:ZCG% AND ZCG.D_E_L_E_T_=''
		AND ZCG_CONTA BETWEEN %Exp:mv_par01% AND %Exp:mv_par02%
		AND ZCG_EMISSA BETWEEN %Exp:mv_par03% AND %Exp:mv_par04%
		AND ZCG_DEPOS <> ' '
		AND ZCG_IRTIP BETWEEN ' ' AND 'Z'
		AND ZCG_REGIST=ZCF_REGIST
	WHERE ZCF.D_E_L_E_T_ = ''
	AND ZCF_UNIDAD BETWEEN %Exp:mv_par17% AND %Exp:mv_par18%
	AND ZCF_IDENT BETWEEN %Exp:mv_par06% AND %Exp:mv_par07%
	AND ZCF_RDR BETWEEN %Exp:mv_par08% AND %Exp:mv_par09%
	AND ZCF_TIPO!='CRD'
	%EXP:_cCndQyr%
EndSql 

TCSETFIELD("QUERY","ZCG_EMISSA","D")

dbSelectArea("QUERY")
dbGoTop()

While !EOF()
	
	lZCF := .T.
	dbGoTop()
	Exit
	
EndDo

If !lZCF

	dbCloseArea()
	
	_cCndQyr := ""
	
	If mv_par05 == 1								
		_cCndQyr += " AND ZCG_DEPOS <> '' "
	ElseIf mv_par05 == 2
		_cCndQyr += " AND ZCG_DEPOS = '' "
	EndIf
	
	If mv_par10 == 1 						//aberto
		_cCndQyr += " AND ZCG_RDR     = '' "
	ElseIf mv_par10 == 2 					//fechado
		_cCndQyr += " AND ZCG_RDR    <> '' "
	ElseIf mv_par10 == 3 					//ambos
		If mv_PAR16 == 1 					//SIM
			_cCndQyr += " AND (ZCG_RDR = '' OR ((ZCG_RDR <> '' AND ZCG_FECRAT = '') AND (SUBSTRING(ZCG_RDR,1,2) <> 'AP'))) " //status (Sempre em aberto)
		Elseif mv_PAR16 == 2 				//NAO
			_cCndQyr += " AND ZCG_RDR = '' " //status (Sempre em aberto)
		EndIf
	EndIf
	
	If mv_par11 == 1
		_cCndQyr += " AND ZCG_IR <> 0 "
	ElseIf mv_par11 == 2
		_cCndQyr += " AND ZCG_IR = 0 "
	EndIf
	
	If mv_par12 == 1
		_cCndQyr += " AND ZCG_IRRDR = '' "
	ElseIf mv_par12 == 2
		_cCndQyr += " AND ZCG_IRRDR <> '' "
	EndIf
	
	_cCndQyr += " AND    ZCG_IRTIP BETWEEN '"+mv_par13+"' AND '"+mv_par14+"' "
	
	If mv_par15 == 1
		_cCndQyr += " AND ZCG_FLUXO   = 'S' "
	ElseIf mv_par15 == 2
		_cCndQyr += " AND ZCG_FLUXO   = ''  "
	EndIf
	
	_cCndQyr += " ORDER BY ZCG_FILIAL,ZCG_CONTA,ZCG_BANCO,ZCG_AGENCI,ZCG_EMISSA,ZCG_VALOR "
	_cCndQyr:= "%"+_cCndQyr+"%"

	BeginSql Alias "QUERY"
		SELECT ZCG_BANCO, 
		       ZCG_AGENCI, 
		       ZCG_CONTA, 
		       ZCG_CONVEN, 
		       ZCG_EMISSA, 
		       ZCG_TIPO, 
		       ZCG_DEPOS, 
		       ZCG_VALOR, 
		       ZCG_NDOC, 
		       ZCG_NAGE, 
		       ZCG_IDENT, 
		       ZCG_BA, 
		       ZCG_CI, 
		       ZCG_RDR, 
		       ZCG_IR, 
		       ZCG_IRTIP, 
		       ZCG_IRRDR, 
		       ZCG_HIST, 
		       ZCG_IMPFLG, 
		       ZCG_UNIDAD, 
		       ZCG_CONV 
		FROM   %table:ZCG% ZCG 
		WHERE  ZCG_CONTA BETWEEN %Exp:mv_par01%  AND %Exp:mv_par01%  
		       AND ZCG_EMISSA BETWEEN %Exp:mv_par03% AND %Exp:mv_par04% 
		       AND ZCG_DEPOS <> ' ' 
		       AND ZCG_IRTIP BETWEEN ' ' AND 'Z' 
		       AND ZCG.D_E_L_E_T_ = '' 
		       AND ZCG_IRTIP BETWEEN ' ' AND 'Z'
		       AND ZCG_UNIDAD BETWEEN %Exp:mv_par17% AND %Exp:mv_par18%
			   AND ZCG_IDENT BETWEEN %Exp:mv_par06% AND %Exp:mv_par07%
			   AND ZCG_RDR BETWEEN %Exp:mv_par08% AND %Exp:mv_par09%
			   AND ZCG_TIPO!='CRD'
		       %EXP:_cCndQyr% 
	    EndSql   
    TCSETFIELD("QUERY","ZCG_EMISSA","D")
    dbSelectArea("QUERY")
    dbGoTop()   
EndIf

nLin       := 80

While !EOF()
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Exit
	Endif
	
	If !Empty(QUERY->ZCG_CONVEN)
		Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " + Alltrim(QUERY->ZCG_CONTA) + " - " + QUERY->ZCG_CONVEN
	Else
		Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " + Alltrim(QUERY->ZCG_CONTA)
	EndIf	
	Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	nLin := 9
	
	_cBanco      := QUERY->ZCG_BANCO
	_cAgencia    := QUERY->ZCG_AGENCI
	_cConta      := QUERY->ZCG_CONTA
	
	_nDia_V := 0
	_nDia_B := 0
	_nDia_C := 0
	_nDia_I := 0
	
	_nBco_V    := 0
	_nBco_B    := 0
	_nBco_C    := 0
	_nBco_I    := 0
	_nContCre  := 0
	While !EOF() .And. 	_cConta+_cBanco+_cAgencia == QUERY->ZCG_CONTA+QUERY->ZCG_BANCO+QUERY->ZCG_AGENCI
		
		If nLin > 65 // Salto de Página. Neste caso o formulario tem 55 linhas...
			If !Empty(QUERY->ZCG_CONVEN)
				Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " + Alltrim(QUERY->ZCG_CONTA) + " - " + QUERY->ZCG_CONVEN
			Else
				Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " + Alltrim(QUERY->ZCG_CONTA)
			EndIf	
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 9
		Endif
		
		_dEmissao   := DTOS(QUERY->ZCG_EMISSA)
		_dEmis      := QUERY->ZCG_EMISSA
		
		_nDia_V := 0
		_nDia_B := 0
		_nDia_C := 0
		_nDia_I := 0

/*        1         2         3         4         5         6         7         8         9        10        11        12        13        14        15        16        17        18        19        20        21        22
01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
Data     | Tipo/Documento         | Depositante                              |          Valor | Documento       | No.  | Agencia              | Identificacao |           B.A. |           C.I. | Irregularidade | RDR          
99/99/99 | xxxxxxxxxxxxxxxxxxxxxx | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx | 999,999,999.99 | 999999999999999 | 9999 | xxxxxxxxxxxxxxxxxxxx | xxxxxxxxxxxxx | 999,999,999.99 | 999,999,999.99 | 999,999,999.99 | 999999
*/                                                                                                                  
		
		While !EOF() .And. 	_cConta+_cBanco+_cAgencia+_dEmissao == QUERY->ZCG_CONTA+QUERY->ZCG_BANCO+QUERY->ZCG_AGENCI+DTOS(QUERY->ZCG_EMISSA)
			
			If nLin > 65 // Salto de Página. Neste caso o formulario tem 55 linhas...
				If !Empty(QUERY->ZCG_CONVEN)
					Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " + Alltrim(QUERY->ZCG_CONTA) + " - " + QUERY->ZCG_CONVEN
				Else
					Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " + Alltrim(QUERY->ZCG_CONTA)
				EndIf	
				Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
				nLin := 9
			Endif

			@ nLin, 000 PSay QUERY->ZCG_EMISSA
			@ nLin, 009 PSay "|"
			
			If	!Empty(QUERY->ZCG_HIST) .and. QUERY->ZCG_IMPFLG == "S"
				_cHist	:=	Substr(Alltrim(QUERY->ZCG_HIST),1,25)
			Else
//				_cHist	:= QUERY->ZCG_TIPO+"-"+LEFT(POSICIONE("SZ9",2,xFilial("SZ9")+QUERY->ZCG_TIPO,"Z9_TIPO_D"),15)
				_cHist	:= LEFT(POSICIONE("SZ9",2,xFilial("SZ9")+QUERY->ZCG_TIPO,"Z9_TIPO_D"),25)
			EndIf
			
			@ nLin, 011 PSay _cHist
			@ nLin, 034 PSay "|"
			@ nLin, 036 PSay substr(QUERY->ZCG_DEPOS,1,40) //Alterado dia 04/11/11 pelo analista Emerson. Neste dia foi alterado o campo de 40 para 80 posicoes
			@ nLin, 077 PSay "|"
			@ nLin, 079 PSay QUERY->ZCG_VALOR Picture "@E 999,999,999.99"
			@ nLin, 094 PSay "|"
			@ nLin, 096 PSay QUERY->ZCG_NDOC
			@ nLin, 112 PSay "|"
			@ nLin, 114 PSay QUERY->ZCG_UNIDAD		//Alterado dia 21/06 pelo analista Emerson. O campo QUERY->ZCG_NAGE era o conteudo anterior
			@ nLin, 119 PSay "|"
			@ nLin, 121 PSay QUERY->ZCG_CONV			//Alterado dia 21/06 pelo analista Emerson. O campo LEFT(POSICIONE("SZA",1,xFilial("SZA")+QUERY->ZCG_NAGE,"ZA_NAGE_D"),20) era o conteudo anterior
			@ nLin, 142 PSay "|"
			@ nLin, 144 PSay QUERY->ZCG_IDENT+"-"+LEFT(POSICIONE("SZB",1,xFilial("SZB")+QUERY->ZCG_IDENT,"ZB_IDENT_D"),10)
			@ nLin, 158 PSay "|"
			@ nLin, 160 PSay QUERY->ZCG_BA Picture "@E 999,999,999.99"
			@ nLin, 175 PSay "|"
			@ nLin, 177 PSay QUERY->ZCG_CI Picture "@E 999,999,999.99"
			@ nLin, 192 PSay "|"
			@ nLin, 194 PSay QUERY->ZCG_IR Picture "@E 999,999,999.99"
			//			@ nLin, 205 PSay QUERY->ZCG_IRTIP
			@ nLin, 210 PSay "|"
			@ nLin, 212 PSay QUERY->ZCG_RDR
			
			If mv_par11<>2 .And. QUERY->ZCG_IR<>0
				nLin ++
				@ nLin, 192 PSay "|"
				@ nLin, 194 PSay QUERY->ZCG_IR Picture "@E 999,999,999.99"
				If QUERY->ZCG_IRTIP == "B"
					@ nLin, 212 PSay "B.A."
				ElseIf QUERY->ZCG_IRTIP == "C"
					@ nLin, 212 PSay "C.I."
				ElseIf QUERY->ZCG_IRTIP == "D"
					@ nLin, 212 PSay "Dev."
				EndIf
				@ nLin, 214 PSay "|"
				@ nLin, 216 PSay QUERY->ZCG_IRRDR
				
				//		    	@ nLin, 205 PSay QUERY->ZCG_IRTIP
				//     			@ nLin, 207 PSay "|"
				//	    		@ nLin, 209 PSay QUERY->ZCG_IRRDR
				nLin ++
			EndIf
			_nContCre++
			_nDia_V := _nDia_V + QUERY->ZCG_VALOR
			_nDia_B := _nDia_B + QUERY->ZCG_BA
			_nDia_C := _nDia_C + QUERY->ZCG_CI
			_nDia_I := _nDia_I + QUERY->ZCG_IR
			
			_nBco_V := _nBco_V + QUERY->ZCG_VALOR
			_nBco_B := _nBco_B + QUERY->ZCG_BA
			_nBco_C := _nBco_C + QUERY->ZCG_CI
			_nBco_I := _nBco_I + QUERY->ZCG_IR
			
			_nBcoG_V := _nBcoG_V + QUERY->ZCG_VALOR
			_nBcoG_B := _nBcoG_B + QUERY->ZCG_BA
			_nBcoG_C := _nBcoG_C + QUERY->ZCG_CI
			_nBcoG_I := _nBcoG_I + QUERY->ZCG_IR
			
			dbSelectArea("QUERY")
			dbSkip()
			nLin ++
		EndDo
		
		nLin ++
		@ nLin, 000 PSay "T o t a l  D i a ==> "
//		@ nLin, 011 PSay _dEmis
		@ nLin, 077 PSay "|"
		@ nLin, 079 PSay _nDia_V Picture "@E 999,999,999.99"
		@ nLin, 094 PSay "|"
		@ nLin, 158 PSay "|"
		@ nLin, 160 PSay _nDia_B Picture "@E 999,999,999.99"
		@ nLin, 175 PSay "|"
		@ nLin, 177 PSay _nDia_C Picture "@E 999,999,999.99"
		@ nLin, 192 PSay "|"
		@ nLin, 194 PSay _nDia_I Picture "@E 999,999,999.99"
		@ nLin, 210 PSay "|"
		
		nLin ++
		nLin ++
//		nLin ++
	EndDo
	
	nLin ++
	@ nLin, 000 PSay "T o t a l  B a n c o  ==> "  //+_cBanco+"-"+_cAgencia+"/"+_cConta
	@ nLin, 077 PSay "|"
	@ nLin, 079 PSay _nBco_V Picture "@E 999,999,999.99"
	@ nLin, 094 PSay "|"
	@ nLin, 158 PSay "|"
	@ nLin, 160 PSay _nBco_B Picture "@E 999,999,999.99"
	@ nLin, 175 PSay "|"
	@ nLin, 177 PSay _nBco_C Picture "@E 999,999,999.99"
	@ nLin, 192 PSay "|"
	@ nLin, 194 PSay _nBco_I Picture "@E 999,999,999.99"
	@ nLin, 210 PSay "|"
	nLin ++
	nLin ++
	nLin ++
	@ nLin, 000 PSay "T o t a l  d e  C r e d i t o (s)  ==> " 
	@ nLin, 077 PSay "|"
	@ nLin, 079 PSay _nContCre Picture "@E 999,999,999"
	@ nLin, 094 PSay "|"
    nLin ++
	nLin ++
	
EndDo

If nLin > 65 // Salto de Página. Neste caso o formulario tem 55 linhas...
	If !Empty(QUERY->ZCG_CONVEN)
		Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " + Alltrim(QUERY->ZCG_CONTA) + " - " + QUERY->ZCG_CONVEN
	Else
		Cabec1:= "Banco: "+ QUERY->ZCG_BANCO + " - Agencia: "+ QUERY->ZCG_AGENCI + " / Conta: " + Alltrim(QUERY->ZCG_CONTA)
	EndIf	
	Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	nLin := 9
Endif

nLin ++ 
@ nLin, 000 PSay Replicate("-",220)
nLin ++  
@ nLin, 000 PSay "T O T A L   G E R A L   B A N C O (S)  ==> " //+_cBanco+"-"+_cAgencia+"/"+_cConta
@ nLin, 077 PSay "|"
@ nLin, 079 PSay _nBcoG_V Picture "@E 999,999,999.99"
@ nLin, 094 PSay "|"
@ nLin, 158 PSay "|"
@ nLin, 160 PSay _nBcoG_B Picture "@E 999,999,999.99"
@ nLin, 175 PSay "|"
@ nLin, 177 PSay _nBcoG_C Picture "@E 999,999,999.99"
@ nLin, 192 PSay "|"
@ nLin, 194 PSay _nBcoG_I Picture "@E 999,999,999.99"
@ nLin, 210 PSay "|"
nLin ++
@ nLin, 000 PSay Replicate("-",220)
nLin ++  

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