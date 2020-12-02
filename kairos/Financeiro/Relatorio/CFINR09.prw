#Include 'rwmake.ch'
#Include 'Topconn.ch'

#DEFINE ENTRADA 1
#DEFINE SAIDA   2
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CFINR09
Extrato Bancario Especifico CIEE	baseado em FINR470
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CFINR09()
LOCAL wnrel
LOCAL cDesc1	 	:= "Este programa ir  emitir o relat¢rio de movimenta‡”es"
LOCAL cDesc2	 	:= "banc rias em ordem de data. Poder  ser utilizado para"
LOCAL cDesc3	 	:= "conferencia de extrato."
LOCAL cString	 	:= "SE5"
LOCAL Tamanho	 	:= "G"
Local _aAreaSE5	:= SE5->(GetArea())
PRIVATE LIMITE   	:= 220
PRIVATE titulo   	:= OemToAnsi("Extrato Bancario")
PRIVATE cabec1
PRIVATE cabec2
PRIVATE aReturn  	:= { OemToAnsi("Zebrado"), 1,OemToAnsi("Administracao"), 2, 2, 1, "",1 }
PRIVATE nomeprog 	:= "CFINR09"
PRIVATE aLinha   	:= { },nLastKey := 0
PRIVATE cPerg	 	:= "CFINR09   "
PRIVATE _aAliases	:= {}


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica as perguntas selecionadas 							 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If .not. U_TemSX1( cPerg )
	Return
Endif
pergunte(cPerg,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Envia controle para a fun‡„o SETPRINT 						 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

wnrel := "CFINR09"            //Nome Default do relatorio em Disco
WnRel := SetPrint(cString,wnrel,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,"",.T.,Tamanho,"")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Envia controle para a funcao REPORTINI substituir as variaveis.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

RptStatus({|lEnd| C6R09RUN(@lEnd,wnRel,cString)},titulo)

DbSelectArea("SE5")
DbGotop()
RestArea(_aAreaSE5)

Return
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C6R09RUN
Rotina de processamento do relatorio
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function C6R09RUN(lEnd,wnRel,cString)

LOCAL CbCont,CbTxt
LOCAL tamanho	  := "M"
LOCAL cBanco,cNomeBanco,cAgencia,cConta,nRec,cLimCred
LOCAL limite 	  := 132
LOCAL nSaldoAtu	  := 0,nTipo,nEntradas:=0,nSaidas:=0,nSaldoIni:=0
LOCAL cDOC
LOCAL cFil	  	  := ""
LOCAL nOrdSE5 	  := SE5->(IndexOrd())
LOCAL cChave
LOCAL cIndex
LOCAL aRecon 	  := {}
Local nTxMoeda 	  := 1
Local nValor 	  := 0
Local aStru 	  := SE5->(dbStruct()), ni
Local nMoeda	  := 1
Local nMoedaBco	  := 1
LOCAL nSalIniStr  := 0
LOCAL nSalIniCip  := 0
LOCAL nSalIniComp := 0
LOCAL nSalStr	  := 0
LOCAL nSalCip	  := 0
LOCAL nSalComp	  := 0
LOCAL lSpbInUse	  := SpbInUse()
LOCAL aStruct	  := {}
Local cFilterUser
Local _cColabor   := ""
Local aFWGetSX5	  := {}
Local cDescSX5	  := ""
Local nPos		  := 0 
Local _cExtrato   := ""


AAdd( aRecon, {0,0} ) // CONCILIADOS
AAdd( aRecon, {0,0} ) // NAO CONCILIADOS
AAdd( aRecon, {0,0} ) // SUB-TOTAL
AAdd( aRecon, {0,0} ) // SUB-TOTAL DIA

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para Impressao do Cabecalho e Rodape	 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

cbtxt 	:= SPACE(10)
cbcont	:= 0
li 		:= 80
m_pag 	:= 1
nTipo   :=IIF(aReturn[4]==1,15,18)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Defini‡„o dos cabe‡alhos									 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Do Case
	Case cEmpant $ '01/02'
	If mv_par05 == 1
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Geral CIEE / SP Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Geral CIEE / SP Entre "
		EndIf
	ElseIf mv_par05 == 2
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Dos Conciliados CIEE / SP Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Dos Conciliados CIEE / SP Entre "
		EndIf
	ElseIf mv_par05 == 3
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Dos Nao Conciliados CIEE / SP Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Dos Nao Conciliados CIEE / SP Entre "
		EndIf
	EndIf
	Case cEmpant == '03'
	If mv_par05 == 1
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Geral CIEE / RJ Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Geral CIEE / RJ Entre "
		EndIf
	ElseIf mv_par05 == 2
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Dos Conciliados CIEE / RJ Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Dos Conciliados CIEE / RJ Entre "
		EndIf
	ElseIf mv_par05 == 3
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Dos Nao Conciliados CIEE / RJ Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Dos Nao Conciliados CIEE / RJ Entre "
		EndIf
	EndIf
	Case cEmpant == '05'
	If mv_par05 == 1
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Geral CIEE / NACIONAL Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Geral CIEE / NACIONAL Entre "
		EndIf
	ElseIf mv_par05 == 2
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Dos Conciliados CIEE / NACIONAL Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Dos Conciliados CIEE / NACIONAL Entre "
		EndIf
	ElseIf mv_par05 == 3
		If mv_par06 == 1
			_cExtrato:="EXTRATO BANCARIO Analitico Dos Nao Conciliados CIEE / NACIONAL Entre "
		Else
			_cExtrato:="EXTRATO BANCARIO Sintetico Dos Nao Conciliados CIEE / NACIONAL Entre "
		EndIf
	EndIf
EndCase	

/*
-----------------------------------------------------------------------------------------------------------------
PRIMEIRO FILTRO
-----------------------------------------------------------------------------------------------------------------
*/

SetRegua(RecCount())
DbSelectArea("SE5")
DbSetOrder(1)
cChave := "E5_FILIAL+DTOS(E5_DTDISPO)+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ"
cOrder := SqlOrder(cChave)
cQuery := "SELECT * "
cQuery += " FROM " + RetSqlName("SE5") + " WHERE "
cQuery += "		E5_FILIAL = '" + xFilial("SE5") + "'" + " AND "
cQuery += " D_E_L_E_T_ <> '*' "
cQuery += " AND E5_DTDISPO >=  '"     + DTOS(mv_par03) + "'"
cQuery += " AND E5_DTDISPO <=  '"     + DTOS(mv_par04) + "'"
cQuery += " AND E5_CONTA BETWEEN '"   + mv_par01 + "' AND '"+ mv_par02 +"' "
cQuery += " AND E5_SITUACA = ' ' "
cQuery += " AND E5_VALOR <> 0 "
cQuery += " AND E5_NUMCHEQ NOT LIKE '%*' "
cQuery += " AND E5_TIPODOC IN ('BA','VL','CH','PA') " //AND E5_MOEDA IN ('01') ALTERADO MOEDA DE BRANCO PARA 01
 
If mv_par05 == 2
	cQuery += " AND E5_RECONC <> ' ' "
ElseIf mv_par05 == 3
	cQuery += " AND E5_RECONC = ' ' "
EndIf
cQuery += " AND E5_RECPAG = 'P' "
cQuery += " ORDER BY " + cOrder

cQuery := ChangeQuery(cQuery)

dbSelectArea("SE5")
dbCloseArea()

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'SE5', .T., .T.)

For ni := 1 to Len(aStru)
	If aStru[ni,2] != 'C'
		TCSetField('SE5', aStru[ni,1], aStru[ni,2],aStru[ni,3],aStru[ni,4])
	Endif
Next

cFilterUser := aReturn[7]
_aEstrut  	:= {}

// Define a estrutura do arquivo de trabalho.
_aEstrut := {	{"E5_RECPAG"  , "C", 01, 0},; 
				{"E5_DTDISPO" , "D", 08, 0},;
				{"E5_DOCUMEN" , "C", 15, 0},;
				{"E5_NUMCHEQ" , "C", 15, 0},;
				{"E5_MOEDA"   , "C", 02, 0},;
				{"E5_TIPODOC" , "C", 02, 0},;
				{"E5_BANCO"   , "C", 03, 0},;
				{"E5_MOTBX"   , "C", 03, 0},;
				{"E5_BENEF"   , "C", 30, 0},;
				{"E5_VLMOED2" , "N", 14, 2},;
				{"E5_VALOR"   , "N", 17, 2},;
				{"E5_RECONC"  , "C", 01, 0},;
				{"E5_HISTOR"  , "C", 40, 0},;
				{"E5_AGENCIA" , "C", 05, 0},;
				{"E5_CONTA"   , "C", 10, 0},;
				{"E5_NUMBOR"  , "C", 06, 0},;
				{"E5_XTIPO"   , "C", 05, 0},;
				{"E5_NUMERO"  , "C", 09, 0},;
				{"E5_TIPO"    , "C", 03, 0}}

//For ni := 1 to Len(_aEstrut)
//	If _aEstrut[ni,2] != 'C'
//		TCSetField('SE5', _aEstrut[ni,1], _aEstrut[ni,2],_aEstrut[ni,3],_aEstrut[ni,4])
//	Endif
//Next

// Cria o indice para o arquivo.
//IndRegua("TMP", _cArqTrab, "DTOS(E5_DTDISPO)+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ+E5_DOCUMEN+E5_RECPAG+STR(E5_VALOR,17,2)",,, "Criando indice...", .T.)
//IndRegua("TMP", _cArqTrab, "E5_BANCO+E5_AGENCIA+E5_CONTA+DTOS(E5_DTDISPO)+E5_NUMCHEQ+E5_DOCUMEN+E5_RECPAG+STR(E5_VALOR,17,2)",,, "Criando indice...", .T.)

_cArqTrab := U_uCriaTrab("TMP",_aEstrut, {{"E5_BANCO","E5_AGENCIA","E5_CONTA","E5_DTDISPO","E5_NUMCHEQ","E5_DOCUMEN","E5_RECPAG","E5_VALOR"}})

DbSelectarea("SE5")
dbGoTop()
While !Eof()
	If SE5->E5_TIPO == "FL "
	   SE5->(DBSKIP())
	   LOOP
	ENDIF   
	dbSelectArea("TMP")
	RecLock("TMP", .T.)
	TMP->E5_RECPAG   := "P"
	TMP->E5_DTDISPO  := SE5->E5_DTDISPO
	TMP->E5_NUMCHEQ  := SE5->E5_NUMCHEQ
	TMP->E5_MOEDA    := SE5->E5_MOEDA
	TMP->E5_TIPODOC  := SE5->E5_TIPODOC
	TMP->E5_BANCO    := SE5->E5_BANCO
	TMP->E5_AGENCIA  := SE5->E5_AGENCIA
	TMP->E5_CONTA    := SE5->E5_CONTA
	TMP->E5_MOTBX    := SE5->E5_MOTBX
	TMP->E5_VLMOED2  := SE5->E5_VLMOED2
	TMP->E5_VALOR    := SE5->E5_VALOR
	TMP->E5_HISTOR   := SE5->E5_HISTOR
	TMP->E5_NUMERO   := SE5->E5_NUMERO
	TMP->E5_TIPO     := SE5->E5_TIPO
	If Empty(SE5->E5_NUMCHEQ) .and. SE5->E5_TIPODOC == "PA"
		cNumBor := Posicione("SE2",1,xFilial("SE2")+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO+SE5->E5_CLIFOR+SE5->E5_LOJA,"E2_NUMBOR")
		If !Empty(cNumbor)
			TMP->E5_NUMBOR	 :=	cNumBor
		Endif	
	Endif
	If !EMPTY(SE5->E5_NUMCHEQ)
		TMP->E5_BENEF    := SE5->E5_BENEF
	Else
		If SE5->E5_TIPO == "PBA"
			TMP->E5_BENEF :="Pagamento Bolsa Auxilio"
		Else
			TMP->E5_BENEF := "Bordero para pgto."
		EndIf
	EndIf
	TMP->E5_DOCUMEN  := SE5->E5_DOCUMEN
	TMP->E5_RECONC   := SE5->E5_RECONC
	TMP->E5_XTIPO    := SE5->E5_XTIPO
	msUnLock()
	DbSelectarea("SE5")
	dbSkip()
EndDo

dbSelectArea("SE5")
dbCloseArea()

/*
--------------------------------------------------------------------------------------------------------------------------------
MANUAL lancamentos do SE5 para TR-Tarifa, TB-Transferencia, BA-Pgto Bolsa Auxilio por Carta, FL-Ficha Lançamento, AP- Aplicação
--------------------------------------------------------------------------------------------------------------------------------
*/

DbSelectArea("SE5")
DbSetOrder(1)
cChave  := "E5_FILIAL+DTOS(E5_DTDISPO)+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ"
cOrder := SqlOrder(cChave)
cQuery := "SELECT * "
cQuery += " FROM " + RetSqlName("SE5") + " WHERE "
cQuery += "	E5_FILIAL = '" + xFilial("SE5") + "'" + " AND "
cQuery += " D_E_L_E_T_ <> '*' "
cQuery += " AND E5_DTDISPO >=  '"     + DTOS(mv_par03) + "'"
cQuery += " AND E5_DTDISPO <=  '"     + DTOS(mv_par04) + "'"
cQuery += " AND E5_CONTA BETWEEN '"   + mv_par01 + "' AND '"+ mv_par02 +"' "
cQuery += " AND E5_SITUACA = ' ' "
cQuery += " AND E5_VALOR <> 0 "
/*
Alterado dia 10/03/10 pelo analista Emerson
Tiramos a MOEDA = 'RC' (Reclassificacao) do relatorio do Extrato pois este movimento deve aparecer apenas uma vez com a MOEDA = 'NI'
*/
If mv_par05 ==1 // Todos
	cQuery += " AND ( (E5_TIPODOC IN ('  ')      AND E5_MOEDA IN ('TB','BA','FL','AP','CD','ES','GE','DD','RG','NI','RS','DE'))OR "
    cQuery += "       (E5_TIPODOC IN ('BA')      AND E5_TIPO  IN ('FL ')                                       )OR "	
	cQuery += "       (E5_TIPODOC IN ('TR') AND E5_MOEDA IN ('TR','TE')                                        )  )"
ElseIf mv_par05 == 2 // Conciliados
	cQuery += " AND ( (E5_TIPODOC IN ('  ')      AND E5_MOEDA IN ('TB','BA','FL','AP','CD','ES','GE','DD','RG','NI','RS','DE') AND E5_RECONC <> ' ' ) OR "
    cQuery += "       (E5_TIPODOC IN ('BA')      AND E5_TIPO  IN ('FL ')                                        AND E5_RECONC <> ' ' ) OR "		
	cQuery += "       (E5_TIPODOC IN ('TR') AND E5_MOEDA IN ('TR','TE')                                         AND E5_RECONC <> ' ' )   )"
ElseIf mv_par05 == 3 // Nao Conciliados
	cQuery += " AND ( (E5_TIPODOC IN ('  ')      AND E5_MOEDA IN ('TB','BA','FL','AP','CD','ES','GE','DD','RG','NI','RS','DE') AND E5_RECONC =  ' ' ) OR "
    cQuery += "       (E5_TIPODOC IN ('BA')      AND E5_TIPO  IN ('FL ')                                   AND E5_RECONC =  ' ' ) OR "			
	cQuery += "       (E5_TIPODOC IN ('TR') AND E5_MOEDA IN ('TR','TE')                                         AND E5_RECONC =  ' ' )   ) "
EndIf
cQuery += " ORDER BY " + cOrder

cQuery := ChangeQuery(cQuery)

dbSelectAreA("SE5")
dbCloseArea()

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'SE5', .T., .T.)

For ni := 1 to Len(aStru)
	If aStru[ni,2] != 'C'
		TCSetField('SE5', aStru[ni,1], aStru[ni,2],aStru[ni,3],aStru[ni,4])
	Endif
Next

DbSelectarea("SE5")
dbGoTop()
While !Eof()
	dbSelectArea("TMP")
	RecLock("TMP", .T.)
	TMP->E5_RECPAG   := SE5->E5_RECPAG //"P"
	TMP->E5_DTDISPO  := SE5->E5_DTDISPO
	TMP->E5_NUMCHEQ  := SE5->E5_NUMCHEQ
	TMP->E5_MOEDA    := SE5->E5_MOEDA
	TMP->E5_TIPODOC  := SE5->E5_TIPODOC
	TMP->E5_BANCO    := SE5->E5_BANCO
	TMP->E5_AGENCIA  := SE5->E5_AGENCIA
	TMP->E5_CONTA    := SE5->E5_CONTA
	TMP->E5_MOTBX    := SE5->E5_MOTBX
	TMP->E5_VLMOED2  := SE5->E5_VLMOED2
	TMP->E5_VALOR    := SE5->E5_VALOR
	TMP->E5_HISTOR   := SE5->E5_HISTOR
	If SE5->E5_MOEDA $ "TB"
		TMP->E5_BENEF    := "Despesa Bancaria"
		TMP->E5_DOCUMEN  := "TARIFA"
		TMP->E5_RECONC   := SE5->E5_RECONC
	ElseIf SE5->E5_MOEDA $ "TR;TE"
		TMP->E5_BENEF    := "Transferencia Bancaria"
		TMP->E5_DOCUMEN  := "TRANSFERENCIA"
		TMP->E5_RECONC   := SE5->E5_RECONC
	ElseIf SE5->E5_MOEDA $ "BA"
		TMP->E5_BENEF    := "Pagamento Bolsa Auxilio"
		TMP->E5_DOCUMEN  := SE5->E5_DOCUMEN
		TMP->E5_RECONC   := SE5->E5_RECONC
	ElseIf SE5->E5_MOEDA $ "ES"
		TMP->E5_BENEF    := "Estorno Bancario"
		TMP->E5_DOCUMEN  := SE5->E5_DOCUMEN
		TMP->E5_RECONC   := SE5->E5_RECONC
	ElseIf SE5->E5_MOEDA $ "AP;CD;GE;DD;RG;RS"
		TMP->E5_BENEF    := SE5->E5_BENEF
		TMP->E5_DOCUMEN  := SE5->E5_DOCUMEN
		TMP->E5_RECONC   := SE5->E5_RECONC
	ElseIf SE5->E5_TIPO == "FL "
		TMP->E5_BENEF    := SE5->E5_BENEF
		TMP->E5_DOCUMEN  := "FL "+AllTrim(SE5->E5_NUMERO)
		TMP->E5_RECONC   := SE5->E5_RECONC
	ElseIf SE5->E5_MOEDA == "NI"
		TMP->E5_BENEF    := "Nao Identificados"
		TMP->E5_DOCUMEN  := SE5->E5_DOCUMEN
		TMP->E5_RECONC   := SE5->E5_RECONC		
	ElseIf SE5->E5_MOEDA == "DE"
//Alterado dia 18/05/09 - analista Emerson Natali
//Acrescentado nome do colaborador
//		TMP->E5_BENEF    := "Movimento Cartao Empresa"
		TMP->E5_BENEF    := "Mov.Cartao "+Substr(Posicione("SZK",4,xFilial("SZK")+alltrim(SE5->E5_XCARTAO),"SZK->ZK_NOME"),1,30)
		TMP->E5_DOCUMEN  := SE5->E5_XCARTAO
		TMP->E5_RECONC   := SE5->E5_RECONC				
	EndIf
	TMP->E5_XTIPO := SE5->E5_XTIPO
	msUnLock()
	DbSelectarea("SE5")
	dbSkip()
EndDo

dbSelectArea("SE5")
dbCloseArea()
/*
-----------------------------------------------------------------------------------------------------------------
PROVISIONAMENTO
No provisionamento altera a data para o dia seguinte
-----------------------------------------------------------------------------------------------------------------
*/

If mv_par05 <> 2 // Todos e Nao Conciliados
	
	DbSelectarea("SE2")
	_xFilSE2:=xFilial("SE2")
	_xFilSEA:=xFilial("SEA")

	_cOrdem := " E2_FILIAL"
	_cQuery := " SELECT E2_FILIAL, E2_VENCREA, E2_NUMBOR, E2_NUM, E2_NOMFOR, E2_VALOR, E2_DECRESC, E2_ACRESC, E2_SALDO, E2_MOVIMEN, EA_NUMBOR, EA_PORTADO, EA_AGEDEP, EA_NUMCON"
	_cQuery += " FROM "
	_cQuery += RetSqlName("SE2")+" SE2,"
	_cQuery += RetSqlName("SEA")+" SEA"
	_cQuery += " WHERE '"+ _xFilSE2 +"' = E2_FILIAL"
	_cQuery += " AND   '"+ _xFilSEA +"' = EA_FILIAL"
	_cQuery += " AND    E2_NUMBOR = EA_NUMBOR"
	_cQuery += " AND    E2_NUM = EA_NUM"	
	_cQuery += " AND    E2_VENCREA = '"+DTOS(mv_par04)+"'"
	_cQuery += " AND    E2_SALDO   > 0 "
	_cQuery += " AND    E2_NUMBOR <> ''"
	_cQuery += " AND    E2_TIPO <> 'PA'"	
	_cQuery += " AND    E2_MOVIMEN = ''"
	_cQuery += " AND    EA_NUMCON  BETWEEN '"   + mv_par01 + "' AND '"+ mv_par02 +"' "
	_cQuery += " AND    SE2.D_E_L_E_T_ = ''"
	_cQuery += " AND    SEA.D_E_L_E_T_ = ''"

	U_C6R04EQY( @_cQuery,_cOrdem, "QUERY", {"SE2","SEA" },,,.T. )
	
	DbSelectarea("QUERY")
	dbGoTop()
	While !Eof()
		dbSelectArea("TMP")
		RecLock("TMP", .T.)
		TMP->E5_RECPAG   := "P"
		TMP->E5_DTDISPO  := QUERY->E2_VENCREA
		TMP->E5_DOCUMEN  := QUERY->E2_NUMBOR
		TMP->E5_NUMCHEQ  := Space(06)
		TMP->E5_MOEDA    := " "
		TMP->E5_TIPODOC  := "VL"
		TMP->E5_BANCO    := QUERY->EA_PORTADO
		TMP->E5_AGENCIA  := QUERY->EA_AGEDEP
		TMP->E5_CONTA    := QUERY->EA_NUMCON
		TMP->E5_MOTBX    := "DEB"
		TMP->E5_BENEF    := "Bordero para pgto." //QUERY->E2_NOMFOR
		TMP->E5_VLMOED2  := 0.00
		TMP->E5_VALOR    := (QUERY->E2_VALOR - QUERY->E2_DECRESC + QUERY->E2_ACRESC)
		TMP->E5_RECONC   := " "
		TMP->E5_HISTOR   := " "
		TMP->E5_XTIPO    := " "
		msUnLock()
		DbSelectarea("QUERY")
		dbSkip()
	EndDo
	DbSelectarea("QUERY")
	dbCloseArea()
	
EndIf
/*
-----------------------------------------------------------------------------------------------------------------
CNI
-----------------------------------------------------------------------------------------------------------------
*/

If mv_par05 <> 3 // Todos e Conciliados
	
	DbSelectarea("SZ8")
	_xFilSZ8:=xFilial("SZ8")
	_cOrdem := " Z8_FILIAL"
	_cQuery := " SELECT * "
	_cQuery += " FROM "
	_cQuery += RetSqlName("SZ8")+" SZ8"
	_cQuery += " WHERE '"+ _xFilSZ8 +"' = Z8_FILIAL"
	_cQuery += " AND Z8_EMISSAO >= '"+DTOS(mv_par03)+"'"
	_cQuery += " AND Z8_EMISSAO <= '"+DTOS(mv_par04)+"'"
	_cQuery += " AND Z8_CONTA  BETWEEN '"   + mv_par01 + "' AND '"+ mv_par02 +"' "
	_cQuery += " AND Z8_VALOR    > 0 "
	
	U_C6R04EQY( @_cQuery,_cOrdem, "QUERY", {"SZ8" },,,.T. )	
	
	DbSelectarea("QUERY")
	dbGoTop()
	While !Eof()
		dbSelectArea("TMP")
		RecLock("TMP", .T.)
		TMP->E5_RECPAG   := "R"
		TMP->E5_DTDISPO  := QUERY->Z8_EMISSAO
		TMP->E5_DOCUMEN  := "EXTRATO"
		TMP->E5_NUMCHEQ  := Space(06)
		TMP->E5_MOEDA    := " "
		TMP->E5_TIPODOC  := "VL"
		TMP->E5_BANCO    := QUERY->Z8_BANCO
		TMP->E5_AGENCIA  := QUERY->Z8_AGENCIA
		TMP->E5_CONTA    := QUERY->Z8_CONTA
		TMP->E5_MOTBX    := "DEB"
		TMP->E5_BENEF    := "Deposito Bancario"
		TMP->E5_VLMOED2  := 0.00
		TMP->E5_VALOR    := QUERY->Z8_VALOR
		TMP->E5_RECONC   := "x"
		TMP->E5_HISTOR   := " "
		TMP->E5_XTIPO    := " "
		msUnLock()
		DbSelectarea("QUERY")
		dbSkip()
	EndDo
	DbSelectarea("QUERY")
	dbCloseArea()
	
EndIf

/*
-----------------------------------------------------------------------------------------------------------------
Contas de Consumo
-----------------------------------------------------------------------------------------------------------------
*/

If mv_par05 <> 3 // Todos e Conciliados
	
	_xFilSZ5:=xFilial("SZ5")
	_cOrdem := " Z5_FILIAL"
	_cQuery := " SELECT * "
	_cQuery += " FROM "
	_cQuery += RetSqlName("SZ5")+" SZ5"
	_cQuery += " WHERE '"+ _xFilSZ5 +"' = Z5_FILIAL"
	_cQuery += " AND Z5_LANC >= '"+DTOS(mv_par03)+"'"
	_cQuery += " AND Z5_LANC <= '"+DTOS(mv_par04)+"'"
	_cQuery += " AND Z5_CCONTA BETWEEN '"   + mv_par01 + "' AND '"+ mv_par02 +"' "
	_cQuery += " AND Z5_VALOR    > 0 "
	
	U_C6R04EQY( @_cQuery,_cOrdem, "QUERY", {"SZ5"},,,.T. )	
	
	DbSelectarea("QUERY")
	dbGoTop()
	While !Eof()
		dbSelectArea("TMP")
		RecLock("TMP", .T.)
		TMP->E5_RECPAG   := "P"
		TMP->E5_DTDISPO  := QUERY->Z5_LANC
		TMP->E5_DOCUMEN  := "DEB AUTOMATICO"
		TMP->E5_NUMCHEQ  := Space(06)
		TMP->E5_MOEDA    := " "
		TMP->E5_TIPODOC  := "CC"
		TMP->E5_BANCO    := QUERY->Z5_BANCO
		TMP->E5_AGENCIA  := QUERY->Z5_AGENCIA
		TMP->E5_CONTA    := QUERY->Z5_CCONTA
		TMP->E5_MOTBX    := "DEB"
		TMP->E5_BENEF    := "Conta Consumo"
		TMP->E5_VLMOED2  := 0.00
		TMP->E5_VALOR    := QUERY->Z5_VALOR
		TMP->E5_RECONC   := "x"
		TMP->E5_HISTOR   := " "
		TMP->E5_XTIPO    := " "
		msUnLock()
		DbSelectarea("QUERY")
		dbSkip()
	EndDo
	DbSelectarea("QUERY")
	dbCloseArea()
	
EndIf

// Verifica se existe movimento, caso não tenha adiciona saldo SE8
dbSelectArea("TMP")
dbGoTop()
If TMP->(EOF())
	_cOrdem := "E8_FILIAL"
	_cQuery := " SELECT * FROM "+RetSqlName("SE8")+" SE8"
	_cQuery += " WHERE '"+ XFILIAL("SE8") +"' = E8_FILIAL"
	_cQuery += " AND E8_CONTA  BETWEEN '"   + mv_par01 + "' AND '"+ mv_par02 +"' "

	U_C6R04EQY( @_cQuery,_cOrdem, "QUERY", {"SE8"},,,.T. )
	
	DbSelectarea("QUERY")
	dbGoTop()
	While !Eof()
		dbSelectArea("TMP")
		RecLock("TMP", .T.)
		TMP->E5_RECPAG   := "P"
		TMP->E5_DTDISPO  := QUERY->E8_DTSALAT
		TMP->E5_DOCUMEN  := QUERY->E8_CONTA
		TMP->E5_NUMCHEQ  := Space(06)
		TMP->E5_MOEDA    := " "
		TMP->E5_TIPODOC  := "E8"
		TMP->E5_BANCO    := QUERY->E8_BANCO
		TMP->E5_AGENCIA  := QUERY->E8_AGENCIA
		TMP->E5_CONTA    := QUERY->E8_CONTA
		TMP->E5_MOTBX    := ""
		TMP->E5_BENEF    := "" 
		TMP->E5_VLMOED2  := 0
		TMP->E5_VALOR    := 0
		TMP->E5_RECONC   := " "
		TMP->E5_HISTOR   := " "
		TMP->E5_XTIPO    := " "
		msUnLock()
		DbSelectarea("QUERY")
		dbSkip()
	EndDo
	DbSelectarea("QUERY")
	dbCloseArea()
ENDIF

/*
-----------------------------------------------------------------------------------------------------------------
INICIO DA IMPRESSAO
-----------------------------------------------------------------------------------------------------------------
*/

DbSelectArea("SZM")
SZM->(DbSetOrder(02))

//Fecha tabela temporaria para nova abertura com ordeção correta
TMP->(dbCloseArea())

cQryTMP := "SELECT * FROM "+ _cArqTrab:GetRealName()
cQryTMP += " ORDER BY E5_BANCO"
cQryTMP += "		,E5_AGENCIA"
cQryTMP += "		,E5_CONTA"
cQryTMP += "		,E5_DTDISPO"
cQryTMP += "		,E5_NUMCHEQ"
cQryTMP += "		,E5_DOCUMEN"
cQryTMP += "		,E5_RECPAG"
cQryTMP += "		,E5_VALOR"

MPSysOpenQuery(cQryTMP, 'TMP' )

TCSETFIELD('TMP','E5_DTDISPO','D')

dbSelectArea("TMP")
TMP->(dbGoTop())

_lPrim:=.T.

If TMP->(EOF())
	MsgBox("Conta(s) sem movimentacao Bancaria!!!")
	dbSelectArea("SE5")
	dbCloseArea()
	ChKFile("SE5")
	dbSelectArea("SE5")
	dbSetOrder(1)
	U_CCFGE02(_aAliases)
	MS_FLUSH()
	Return
EndIf

cNomeBanco	:= SA6->A6_NREDUZ

titulo := OemToAnsi(_cExtrato)+DTOC(mv_par03) + " e " +Dtoc(mv_par04)
cabec1 := OemToAnsi("BANCO ")+ TMP->E5_BANCO +" - " + ALLTRIM(cNomeBanco) + OemToAnsi("   AGENCIA ")+ TMP->E5_AGENCIA + OemToAnsi("   CONTA ")+ TMP->E5_CONTA
cabec2 := OemToAnsi("DATA        OPERACAO/BENEFICIARIO          DOCUMENTO                                 ENTRADAS          SAIDAS          SALDO ATUAL")

//Saldo de Partida
dbSelectArea("SE8")
dbSetOrder(1)
If dbSeek(xFilial("SE8")+TMP->E5_BANCO+TMP->E5_AGENCIA+TMP->E5_CONTA+Dtos(mv_par03))
	nSaldoAtu:=SE8->E8_XSALCIE
	nSaldoIni:=SE8->E8_XSALCIE
Else
	nSaldoAtu:=0
	nSaldoIni:=0
EndIf

If lSpbInUse
	nSalIniStr := 0
	nSalIniCip := 0
	nSalIniComp := 0
Endif

cBanAgCC := TMP->E5_BANCO+TMP->E5_AGENCIA+TMP->E5_CONTA

dbSelectArea("TMP")
While !Eof()
	// Tratamento para contas sem movimento
	IF TMP->E5_TIPODOC == "E8"
		dbSkip( )
		Loop	
	ENDIF
	
	_dE5_DTDISPO := E5_DTDISPO
	_cE5_DOCUMEN := E5_DOCUMEN
	_cE5_NUMCHEQ := E5_NUMCHEQ
	_cE5_RECPAG  := E5_RECPAG
	_cE5_MOEDA   := E5_MOEDA
	_cE5_TIPODOC := E5_TIPODOC
	_cTit        := SUBSTR(AllTrim(E5_BENEF),1,30)
	_nTotal      := 0
	_cStatus     := " C"
	
	If TMP->E5_BANCO+TMP->E5_AGENCIA+TMP->E5_CONTA <> cBanAgCC
		/*
		*****************************************************************************************************************************
		*/
		If li > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif

		li+=2
		@li,048 PSAY OemToAnsi("SALDO INICIAL...........: ")
		@li,113 PSAY nSaldoIni	Picture tm(nSaldoIni,16,2)

		li+=2
		If li > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif

		li++
		@li,048 PSAY OemToAnsi("CONCILIADOS.............: ")
		@li,078 PSAY aRecon[1][ENTRADA]                            PicTure tm(aRecon[1][1],15,2)
		@li,094 PSAY aRecon[1][SAIDA]                              PicTure tm(aRecon[1][2],15,2)
		@li,113 PSAY nSaldoIni+aRecon[1][ENTRADA]-aRecon[1][SAIDA] PicTure tm(nSaldoIni+aRecon[1][1]-aRecon[1][2],16,2)
		li++
		If li > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		@li,048 PSAY OemToAnsi("NAO CONCILIADOS.........: ")
		@li,078 PSAY aRecon[2][ENTRADA]                  PicTure tm(aRecon[2][1],15,2)
		@li,094 PSAY aRecon[2][SAIDA]                    PicTure tm(aRecon[2][2],15,2)
		@li,113 PSAY nSaldoIni+aRecon[1][ENTRADA]-aRecon[1][SAIDA]+aRecon[2][ENTRADA]-aRecon[2][SAIDA] PicTure tm(nSaldoIni+aRecon[1][ENTRADA]-aRecon[1][SAIDA]+aRecon[2][ENTRADA]-aRecon[2][SAIDA],16,2)
		li++
		If li > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		@li,048 PSAY OemToAnsi("SUB-TOTAL...............: ")
		@li,078 PSAY aRecon[3][ENTRADA]                             PicTure tm(aRecon[3][1],15,2)
		@li,094 PSAY aRecon[3][SAIDA]                               PicTure tm(aRecon[3][2],15,2)
		@li,113 PSAY nSaldoIni+aRecon[3][ENTRADA]-aRecon[3][SAIDA] PicTure tm(nSaldoIni+aRecon[3][1]-aRecon[3][2],16,2)
		li++
		If li > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif

		li+=2

		If li > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		@li, 48 PSAY OemToAnsi("SALDO ATUAL ............: ")
		@li,113 PSAY nSaldoAtu	Picture tm(nSaldoAtu,16,2)

		IF li != 80
			roda(cbcont,cbtxt,Tamanho)
		EndIF

		//Gravando Saldo Bancario SE8 no dia posterior
		If mv_par05==1
			_dDtSld := mv_par04+1
			dbSelectArea("SE8")
			dbSeek(xFilial("SE8")+cBanAgCC+Dtos(_dDtSld))
			If Eof()
				RecLock("SE8",.t.)
			Else
				RecLock("SE8",.f.)
			EndIf
			Replace 	E8_FILIAL   With xFilial("SE8"),;
						E8_BANCO    With Substr(cBanAgCC,1,3),;
						E8_AGENCIA  With Substr(cBanAgCC,4,5),;
						E8_CONTA    With Substr(cBanAgCC,9,10)
			Replace E8_DTSALAT With _dDtSld
			Replace E8_XSALCIE With nSaldoIni+aRecon[1][ENTRADA]-aRecon[1][SAIDA]
			Replace E8_XFLAG    With "X"
			MsUnlock()
		EndIf
		/*
		*****************************************************************************************************************************
		*/

		cabec1 := OemToAnsi("BANCO ")+ TMP->E5_BANCO +" - " + ALLTRIM(cNomeBanco) + OemToAnsi("   AGENCIA ")+ TMP->E5_AGENCIA + OemToAnsi("   CONTA ")+ TMP->E5_CONTA
		li 			:= 80 
		_lPrim		:= .T.
		cBanAgCC 	:= TMP->E5_BANCO+TMP->E5_AGENCIA+TMP->E5_CONTA
		//Saldo de Partida
		dbSelectArea("SE8")
		dbSetOrder(1)
		If dbSeek(xFilial("SE8")+TMP->E5_BANCO+TMP->E5_AGENCIA+TMP->E5_CONTA+Dtos(mv_par03))
			nSaldoAtu:=SE8->E8_XSALCIE
			nSaldoIni:=SE8->E8_XSALCIE
		Else
		nSaldoAtu:=0
		nSaldoIni:=0
		EndIf
		aRecon := {}
		AAdd( aRecon, {0,0} ) // CONCILIADOS
		AAdd( aRecon, {0,0} ) // NAO CONCILIADOS
		AAdd( aRecon, {0,0} ) // SUB-TOTAL
		AAdd( aRecon, {0,0} ) // SUB-TOTAL DIA

	EndIf
	dbSelectArea("TMP")
	While !Eof() .And. _dE5_DTDISPO == E5_DTDISPO .And. _cE5_DOCUMEN == E5_DOCUMEN .And. _cE5_NUMCHEQ == E5_NUMCHEQ .And. _cE5_RECPAG == E5_RECPAG .And. _cE5_TIPODOC == E5_TIPODOC
		
		IF lEnd
			@PROW()+1,0 PSAY OemToAnsi("Cancelado pelo operador")
			EXIT
		Endif
		
		IncRegua()
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Considera filtro do usuario                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		If !Empty(cFilterUser).and.!(&cFilterUser)
			dbSkip()
			Loop
		Endif
		
		IF li > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
			If _lPrim
			   @li ++,113 PSAY nSaldoIni   Picture tm(nSaldoAtu,16,2)
			   _lPrim:=.F.
			Else 
			   @li ++,113 PSAY nSaldoAtu   Picture tm(nSaldoAtu,16,2)
			EndIf   
		EndIF
		
		dbSelectArea("TMP")
		
		If mv_par06 == 1
			@li, 0 PSAY E5_DTDISPO
		EndIf
		
		If mv_par06 == 1
			if !Empty(E5_BENEF)
				@li,12 PSAY SUBSTR(AllTrim(E5_BENEF),1,30)
			else
				@li,12 PSAY space(30)
				If mv_par06 == 1
					If EMPTY(E5_DOCUMEN)
						If Empty(E5_NUMBOR)
							if Empty(E5_XTIPO)
								@li,12 PSAY space(30)
							else
								if !SZM->(DbSeek(xFilial("SZM")+TMP->E5_XTIPO))
									@li,12 PSAY space(30)
								endif
							endif
						Endif
					EndIf
				EndIf
			endif
		EndIf
		
		cDoc := E5_NUMCHEQ
		
		IF Empty( cDoc )
			cDoc := E5_DOCUMEN
		Endif
		IF Len(Alltrim(E5_DOCUMEN)) + Len(Alltrim(E5_NUMCHEQ)) <= 19
			cDoc := Alltrim(E5_DOCUMEN) +if(!empty(Alltrim(E5_DOCUMEN)),"-"," ") + Alltrim(E5_NUMCHEQ )
		Endif
		
		If Empty(cDoc)
			cDoc := Alltrim(E5_NUMERO)
		EndIf
		
		If Substr( cDoc ,1, 1 ) == "*"
			dbSkip( )
			Loop
		Endif
		
		if TMP->E5_VALOR == 2163995.11
			xxx:=""
		endif
		
		If mv_par06 == 1
			If !EMPTY(E5_DOCUMEN)
				If E5_RECPAG  == "P"
					Do Case
						Case ALLTRIM(E5_TIPODOC) $ "VL"
							@li,043 PSAY "BD "+AllTrim(E5_DOCUMEN)
						Case ALLTRIM(E5_TIPODOC) $ "BA"
							@li,043 PSAY "BD "+AllTrim(E5_DOCUMEN)
						Case ALLTRIM(E5_TIPODOC) $ "PA"
							@li,043 PSAY "BD "+AllTrim(E5_DOCUMEN)							
						Case ALLTRIM(E5_TIPODOC) $ "CH"
							@li,043 PSAY "CH "+AllTrim(E5_DOCUMEN)
						OtherWise
							@li,043 PSAY AllTrim(E5_DOCUMEN)
					EndCase
				Else
					@li,043 PSAY AllTrim(E5_DOCUMEN)
				EndIf
			Else
				If !Empty(E5_NUMBOR)
					@li,043 PSAY "BD "+AllTrim(E5_NUMBOR)
				Else
					if Empty(E5_XTIPO)
						If E5_TIPO == "PBA"
							@li,043 PSAY AllTrim(E5_NUMERO)
						Else
							@li,043 PSAY "CH "+AllTrim(E5_NUMCHEQ)
						EndIf 
					else
						if SZM->(DbSeek(xFilial("SZM")+TMP->E5_XTIPO))
							if Empty(E5_BENEF)
								@li,013 PSAY SZM->ZM_DESC + space(10)
							endif

							cDescSX5  := ""
							aFWGetSX5 := FWGetSX5("06")

							For nPos := 1 To Len(aFWGetSX5)
								If  aFWGetSX5[nPos][2]="06" .And. AllTrim(aFWGetSX5[nPos][3])=SZM->ZM_MOEDA
									cDescSX5 := aFWGetSX5[nPos][4]
								EndIf
							Next

							if !EMPTY(cDescSX5)
								if !Empty(E5_BENEF)
									@li,043 PSAY Left(AllTrim(cDescSX5),18)
								else
									@li,044 PSAY Left(AllTrim(cDescSX5),18)
								endif
							else
								@li,043 PSAY "CH "+AllTrim(E5_NUMCHEQ)
							endif
						else
							@li,043 PSAY "CH "+AllTrim(E5_NUMCHEQ)
						endif
					endif
				Endif
			EndIf
		EndIf

/*		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³VerIfica se foi utilizada taxa contratada para moeda > 1          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If nMoeda > 1 .and. !Empty(E5_VLMOED2)
			If  E5_VALOR != E5_VLMOED2
				IF Round(xMoeda(E5_VALOR,nMoedaBco,nMoeda,E5_DTDISPO,nMoeda+1),nMoeda) != E5_VLMOED2
					nTxMoeda := (E5_VALOR * RecMoeda(E5_DTDISPO,nMoedaBco)) / E5_VLMOED2
				Else
					nTxMoeda := RecMoeda(E5_DTDISPO,nMoeda)
				EndIf
				nTxMoeda :=if(nTxMoeda=0,1,nTxMoeda)
				nValor := Round(xMoeda(E5_VALOR,nMoedaBco,nMoeda,,nMoeda+1,,nTxMoeda),nMoeda)
			Else
				nValor := Round(xMoeda(E5_VALOR,nMoedaBco,nMoeda,E5_DTDISPO,nMoeda+1),nMoeda)
			EndIf
		Else
			nValor := Round(xMoeda(E5_VALOR,nMoedaBco,nMoeda,E5_DTDISPO,nMoeda+1),nMoeda)
		Endif
*/
		nValor := TMP->E5_VALOR
		
		If mv_par06 == 1
			If E5_RECPAG == "P"
				if !Empty(E5_BENEF)
					@li,94 PSAY nValor Picture tm(nValor,15,2)
				else
					@li,95 PSAY nValor Picture tm(nValor,15,2)
				endif
			Else
				if !Empty(E5_BENEF)
					@li,78 PSAY nValor Picture tm(nValor,15,2)
				else
					@li,79 PSAY nValor Picture tm(nValor,15,2)
				endif
			EndIf
		EndIf
		
		If E5_RECPAG  == "P"
			nSaldoAtu -= nValor
		Else
			nSaldoAtu += nValor
		EndIf
		
		_nTotal   += nValor
		
		If Empty( E5_RECONC )
			If E5_RECPAG  == "P"
				aRecon[2][SAIDA]   += nValor
			Else
				aRecon[2][ENTRADA] += nValor
			EndIf
		Else
			If E5_RECPAG  == "P"
				aRecon[1][SAIDA]   += nValor
			Else
				aRecon[1][ENTRADA] += nValor
			EndIf
		EndIf
		
		If E5_RECPAG  == "P"
			aRecon[3][SAIDA]   += nValor
			aRecon[4][SAIDA]   += nValor
		Else
			aRecon[3][ENTRADA] += nValor
			aRecon[4][ENTRADA] += nValor
		EndIf
		
		If mv_par06 == 1
			if !Empty(E5_BENEF)
				@li,113 PSAY nSaldoAtu Picture tm(nSaldoAtu,16,2)
			else
				@li,114 PSAY nSaldoAtu Picture tm(nSaldoAtu,16,2)
			endif
			@li++,pCol()PSAY Iif(Empty(E5_RECONC), " ", " C")
		Else
			If Empty(E5_RECONC)
				_cStatus:= " "
			EndIf
		EndIf
		
		dbSelectArea("TMP")
		dbSkip()
		
	EndDo
	
	If mv_par06 == 2 .And. _nTotal <> 0
		@li, 0 PSAY _dE5_DTDISPO
		@li,12 PSAY _cTit
		
		If !EMPTY(_cE5_DOCUMEN)
			If _cE5_RECPAG  == "P"
				Do Case
					Case _cE5_TIPODOC $ "VL"
						@li,043 PSAY "BD "+AllTrim(_cE5_DOCUMEN)
					Case _cE5_TIPODOC $ "BA"
						@li,043 PSAY "BD "+AllTrim(_cE5_DOCUMEN)
					Case _cE5_TIPODOC $ "PA"
						@li,043 PSAY "BD "+AllTrim(_cE5_DOCUMEN)						
					Case _cE5_TIPODOC $ "CH"
						@li,043 PSAY "CH "+AllTrim(_cE5_DOCUMEN)
					OtherWise
						@li,043 PSAY AllTrim(_cE5_DOCUMEN)
				EndCase
			Else
				@li,043 PSAY AllTrim(_cE5_DOCUMEN)
			EndIf
		Else
			@li,043 PSAY "CH "+AllTrim(_cE5_NUMCHEQ)
		EndIf
		
		If _cE5_RECPAG == "P"
			@li,94 PSAY _nTotal Picture tm(nValor,15,2)
		Else
			@li,78 PSAY _nTotal	Picture tm(nValor,15,2)
		EndIf
		
		@li,113 PSAY nSaldoAtu Picture tm(nSaldoAtu,16,2)
		@li++,pCol()PSAY _cStatus
	EndIf
	
	If mv_par05 == 2 .And. _dE5_DTDISPO <> E5_DTDISPO
		li++
		If li > 58
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		@li,000 PSAY OemToAnsi("SUB-TOTAL...............: ")
		@li,078 PSAY aRecon[4][ENTRADA]                            PicTure tm(aRecon[3][1],15,2)
		@li,094 PSAY aRecon[4][SAIDA]                              PicTure tm(aRecon[3][2],15,2)
		@li,113 PSAY nSaldoAtu                                     PicTure tm(nSaldoAtu   ,16,2)
		aRecon[4][ENTRADA] := 0
		aRecon[4][SAIDA]   := 0
		li++
		li++
	EndIf
	
EndDo

If li > 58
	cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
Endif

li+=2
@li,048 PSAY OemToAnsi("SALDO INICIAL...........: ")
@li,113 PSAY nSaldoIni	Picture tm(nSaldoIni,16,2)

li+=2
If li > 58
	cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
Endif

li++
@li,048 PSAY OemToAnsi("CONCILIADOS.............: ")
@li,078 PSAY aRecon[1][ENTRADA]                            PicTure tm(aRecon[1][1],15,2)
@li,094 PSAY aRecon[1][SAIDA]                              PicTure tm(aRecon[1][2],15,2)
@li,113 PSAY nSaldoIni+aRecon[1][ENTRADA]-aRecon[1][SAIDA] PicTure tm(nSaldoIni+aRecon[1][1]-aRecon[1][2],16,2)
li++
If li > 58
	cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
Endif
@li,048 PSAY OemToAnsi("NAO CONCILIADOS.........: ")
@li,078 PSAY aRecon[2][ENTRADA]                  PicTure tm(aRecon[2][1],15,2)
@li,094 PSAY aRecon[2][SAIDA]                    PicTure tm(aRecon[2][2],15,2)
@li,113 PSAY nSaldoIni+aRecon[1][ENTRADA]-aRecon[1][SAIDA]+aRecon[2][ENTRADA]-aRecon[2][SAIDA] PicTure tm(nSaldoIni+aRecon[1][ENTRADA]-aRecon[1][SAIDA]+aRecon[2][ENTRADA]-aRecon[2][SAIDA],16,2)
li++
If li > 58
	cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
Endif
@li,048 PSAY OemToAnsi("SUB-TOTAL...............: ")
@li,078 PSAY aRecon[3][ENTRADA]                             PicTure tm(aRecon[3][1],15,2)
@li,094 PSAY aRecon[3][SAIDA]                               PicTure tm(aRecon[3][2],15,2)
@li,113 PSAY nSaldoIni+aRecon[3][ENTRADA]-aRecon[3][SAIDA] PicTure tm(nSaldoIni+aRecon[3][1]-aRecon[3][2],16,2)
li++
If li > 58
	cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
Endif

li+=2

If li > 58
	cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
Endif
@li, 48 PSAY OemToAnsi("SALDO ATUAL ............: ")
@li,113 PSAY nSaldoAtu	Picture tm(nSaldoAtu,16,2)

IF li != 80
	roda(cbcont,cbtxt,Tamanho)
EndIF

//Gravando Saldo Bancario SE8 no dia posterior
If mv_par05==1
	_dDtSld := mv_par04 + 1
	dbSelectArea("SE8")
	dbSeek(xFilial("SE8")+cBanAgCC+Dtos(_dDtSld))
	If Eof()
		RecLock("SE8",.t.)
	Else
		RecLock("SE8",.f.)
	EndIf
	Replace 	E8_FILIAL   With xFilial("SE8"),;
				E8_BANCO    With Substr(cBanAgCC,1,3),;
				E8_AGENCIA  With Substr(cBanAgCC,4,5),;
				E8_CONTA    With Substr(cBanAgCC,9,10)
	Replace E8_DTSALAT With _dDtSld
	Replace E8_XSALCIE With nSaldoIni+aRecon[1][ENTRADA]-aRecon[1][SAIDA]
	Replace E8_XFLAG    With "X"
	MsUnlock()
EndIf

Set Device To Screen

dbSelectArea("SE5")
dbCloseArea()
ChKFile("SE5")
dbSelectArea("SE5")
dbSetOrder(1)
U_CCFGE02(_aAliases)

If aReturn[5] = 1
	Set Printer To
	dbCommit()
	ourspool(wnrel)
Endif

MS_FLUSH()
Return
