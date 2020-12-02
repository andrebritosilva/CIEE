#INCLUDE "FIVEWIN.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "CGPER04.CH"              
#include "topconn.ch" 

/*==================================================================================================
  Copia da rotina padrao GPEM080 ajustada para geracao dos arquivos de CNAB para todos os tipos 
  de roteiros sendo padrao ou customizado alem da possibilidade de geracao de arquivos para validar
  contas dos funcionarios com 0.01.
@author     Totvs 
@since      
@param
@version    P12
@return
@project
@client    Ciee
           Existir as perguntas especificas no sx1 contidas no pacote. 
19-12-18   Ajustado a rotina para checar a nova pergunta p/ validar as contas bancarias gerando
           o arquivo bancario com R$ 0.01. Qdo preenchido com Sim para validar as contas bancarias
           deve preencher a data de admissao de-ate.        
11-10-19   Ajustado a rotina para considerar certos bancos para fazer doc para o RJ a partir do RJ.            
//================================================================================================== */
User Function CGPER04(lAuto)
Local   cPerg		:= ""
Local oSelf
Private cCadastro 	:= OemToAnsi(STR0001) //"Geracao de liquido em disquete (CNAB/SISPAG)"
Private nSavRec  	:= RECNO()
Private cProcessos	:= ""
Private cNumPedido  := ""
Private cxRoteiros  := ""
Private cxFil       := cvaltochar(Right(cFilAnt,2))          // verifica a filial para filtrar
Private aVerbas     := {}
Private cxVerbas    := ""
Private cTpBenInt   := 'X'
Private aTabS011    := {}
Private lPgtoBA     := IsInCallStack("U_CJOBK03") .or. IsInCallStack("U_CJOBK02") .or. IsInCallStack("U_CFINA92")

Private _lJob		:= GetRemoteType() == -1 // Verifica se é job

Default lAuto := .F.

//FUNCAO VERIFICA SE EXISTE ALGUMA RESTRICAO DE ACESSO PARA O USUARIO QUE IMPECA A EXECUCAO DA ROTINA
If !(fValidFun({"SRQ","SR0"}))
	if lPgtoBA
		U_CJBK03LOG(2,"Existe restrição de usuário para processamento da rotina","1")
		If !_lJob
			Alert("Existe restrição de usuário para processamento da rotina")
		Endif
	endif
	Return( nil )
Endif

//Verifica se exite o grupo de perguntas GPEM080R1
DBSelectArea("SX1")
DBSetOrder(1)
If DBSeek("XGPEM080R1")
	cPerg := "XGPEM080R1"
Else
	if lPgtoBA
		U_CJBK03LOG(2,"Grupo de perguntas XGPEM080R1 não localizado","1")
	Endif
	If !_lJob
		Alert("Grupo de perguntas XGPEM080R1 não localizado")
	Endif
EndIf 

//Tratamento para não chamar o pergunte via calculo do pagamento de bolsa auxilio ou Tribunal de Justiça (Cnab Exclusivo)
If !(lPgtoBA)
	Pergunte(cPerg, .F.)
Endif	

cDescricao := OemToAnsi(STR0002) + CRLF + OemToAnsi(STR0003) + CRLF + OemToAnsi(STR0004)
//" ESTE PROGRAMA TEM O OBJETIVO DE GERAR O ARQUIVO DE LIQUIDO EM DISCO."
//" ANTES DE RODAR ESTE PROGRAMA  E  NECESSARIO CADASTRAR O LAY-OUT DO  "
//" ARQUIVO. MODULO SIGACFG OPCAO CNAB A RECEBER OU SISPAG. "
bProcesso := {|oSelf| GPM080Processa(oSelf, lAuto)}
If ! lAuto
	tNewProcess():New( "GPEM080", cCadastro, bProcesso, cDescricao, cPerg, , .T., 20, cDescricao, .T., .T.)
Else
	GPM080Processa(oSelf, lAuto)
EndIf

Return

/*
*************************************************************************
*Funcao    *Gpm080processa* Autor * Equipe de RH      * Data *13/05/2005*
*************************************************************************
*Descricao *Processamento da geracao do arquivo                         *
*************************************************************************
*Sintaxe   *Gpm080processa()                                            *
*************************************************************************
*Parametros*                                                            *
*************************************************************************
* Uso      * Gpem080                                                    *
*************************************************************************
*/
Static Function Gpm080processa(oSelf, lAuto)
Local aCodFol		:={}
Local lHeader		:= .F.
Local lFirst		:= .F.
Local lGrava		:= .F.
Local lGp410Des 	:= ExistBlock("GP410DES")
Local lGp450Des 	:= ExistBlock("GP450DES")
Local lGp450Val 	:= ExistBlock("GP450VAL")
//Local aVerba		:= {}
Local nCntP, nZ
Local aStruSRA
Local cAliasSRA		:= "SRA2" 	//ALIAS DA QUERY
Local cLocaBco 		:= cLocaPro := ""
Local X				:= 0
Local lAllProc		:= .F.
Local nTamCod		:= 0
//Local cAuxPrc		:= ""
Local lCpyS2T		:= .F.
Local lValidFil		:= .T.
Local nTamFil		:= FWSIZEFILIAL()
//VARIAVEIS PARA CRIACAO DE LOG
Local cLog			:= 	""
Local aLog			:= {}
Local aTitle		:= {}
Local nTotRegs		:= 0
Local nRegsGrav		:= 0
LOcal nTotVal		:= 0
//Local nVerba		:= 0
Local cData			:= ""
Local cHora			:= ""
//ARQUIVO MESES ANTERIORES
//Local nS
Local nX, nxRot
Local cTpConta
Local nPos
Local aFunBenef := {}
Local aRecnosSR0:= {}
Local lMod2Ambos:= .F.
Local cSitQuery := ""
Local cCatQuery := ""
Local cProcQuery:= ""
Local cNomArq	:= ""
Local cNomDir	:= ""
Local FilAnt := Replicate("!", nTamFil)
Local lNewPerg := If (oSelf <> Nil .and. ALLTRIM(oSelf:cPergunte) == "XGPEM080R1", .T., .F.)

Local cFilDe		:= mv_par04
Local cFilAte		:= mv_par05
Local cCcDe     	:= mv_par06
Local cCcate    	:= mv_par07
Local cBcoDe		:= mv_par08
Local cBcoAte		:= mv_par09
Local cMatDe    	:= mv_par10
Local cMatAte		:= mv_par11
Local cNomDe		:= mv_par12
Local cNomAte		:= If (Left(mv_par13,3) == "ZZZ",LOWER(mv_par13),mv_par13)
Local cCtaDe		:= mv_par14
Local cCtaAte		:= mv_par15
Local cSituacao		:= mv_par16
Local cCategoria	:= mv_par23
Local nFunBenAmb	:= mv_par24  // 1-FUNCIONARIOS  2-BENEFICIARIAS  3-AMBOS
//Local dDataRef	:= If (Empty(mv_par25), dDataBase,mv_par25)
Local lLnVazia		:= If (mv_par29 == 1,.T.,.F.)
Local cQtdPedido	:= alltrim(mv_par28)  
//cxRoteiros  := Alltrim(mv_par01 + mv_par02 + mv_par03)
Local cxRoteiros 	:= Alltrim(mv_par01)

Local nQuebra		:= 1
Local nNivel		:= 0
Local lpula			:= .F.	//Define se existira Quebra na geração do CNAB por nivel de escolaridade
Local lCFIN92CN     := IsInCallStack("U_CFIN92CNABEX")
Local lProcessado   := .T.  

Private nModelo		:= mv_par17
Private cArqent		:= mv_par18
Private cArqSaida	:= mv_par19
Private dDataDe		:= mv_par21
Private dDataAte	:= mv_par22
Private dDataPgto   := mv_par20
Private lAmarCtr 	:= mv_par38 == 2	//2= Veio do Fonte FINA92 Gera Cnab TJ 	
Private lAmarct2	:= lAmarCtr
//Private cCI_CNPJTJ  := Alltrim(SuperGetMv("CI_CNPJTJ",.F.,""))

Private cStartPath := GetSrvProfString("StartPath","")
Private cLote	:= Nil
Private cNome,cBanco,cConta,cCPF
Private aValBenef 	:= {}
Private aRoteiros	:= {}
// VARIAVEIS DE ACESSO DO USUARIO
Private cAcessaSR1	:= &( " { || " + ChkRH( "GPER080" , "SR1" , "2" ) + " } " )
Private cAcessaSRA	:= &( " { || " + ChkRH( "GPER080" , "SRA" , "2" ) + " } " )
Private cAcessaSR0	:= &( " { || " + ChkRH( "GPER080" , "SR0" , "2" ) + " } " )
Private cAcessaSRD	:= &( " { || " + ChkRH( "GPER080" , "SRD" , "2" ) + " } " )
Private cAcessaSRG	:= &( " { || " + ChkRH( "GPER080" , "SRG" , "2" ) + " } " )
Private cAcessaSRH	:= &( " { || " + ChkRH( "GPER080" , "SRH" , "2" ) + " } " )
Private cAcessaSRR	:= &( " { || " + ChkRH( "GPER080" , "SRR" , "2" ) + " } " ) 
Private cAcessaSRC	:= &( " { || " + ChkRH( "GPER080" , "SRC" , "2" ) + " } " )
// DEFINE VARIAVEIS PRIVADAS BASICAS
Private aABD := { STR0007,STR0007,STR0006 } //"Drive A"###"Drive B"###"Abandona"
Private aTA  := { STR0005,STR0006 } //"Tenta Novamente"###"Abandona"
// DEFINE VARIAVEIS PRIVADAS DO PROGRAMA
Private nEspaco := nDisco := nGravados := 0
Private cDrive := " "
Private nArq, cTipInsc
// VARIAVEIS USADAS NO ARQUIVO DE CADASTRAMENTO
Private nSeq		:= 0
Private nValor		:= 0
Private nTotal		:= 0
Private nTotFunc	:= 0
// VARIAVEIS DISPONIBILIZADAS PARA GERACAO DO ARQUIVO - MOD.2
Private CIC_ARQ		:= "" //CPF
Private NOME_ARQ		:= "" //Nome Completo
Private PRINOME_ARQ	:= "" //Primeiro Nome
Private SECNOME_ARQ	:= "" //Segundo Nome
Private PRISOBR_ARQ	:= "" //Primeiro Sobrenome
Private SECSOBR_ARQ	:= "" //Segundo Sobrenome
Private BANCO_ARQ	:= "" //Banco
Private CONTA_ARQ	:= "" //Conta
Private lRegFun		:= .F.
Private nHdlBco		:=0,nHdlSaida:=0
Private xConteudo

// BLOCO DE VARIAVEIS PARA CONTROLE DOS DADOS BANCARIOS DA EMPRESA
Private lUsaBanco  := .F.
Private lGeraDOC   := .F.
Private lDocCC	   := .F.
Private lDocPoup   := .F.
Private cCodBanco  := ""
Private cCodAgenc  := ""
Private cDigAgenc  := ""
Private cCodConta  := ""
Private cDigConta  := ""
Private cCodConve  := ""
Private cCodFilial := ""
Private cCodCnpj   := ""
Private cNomeEmpr  := ""
Private lCCorrent  := .T.
Private aInfo      := {}
Private nTipoConta := 0
Private CTPOARCE   := "" // Tipo Archivo Enviado
Private nLoteSeq   := 1 /*Variavel guarda a sequencia atual do Lote*/
Private nLoteTotal := 0 /*--------------- o valor total do Lote atual*/
Private nLoteQtd   := 0 /*--------------- a quantidade de funcionarios do Lote Atual*/
Private nQtdLinLote:= 0 /*--------------- a quantidade de linhas do Lote Atual*/
Private cSeq	   := ""
Private nTotLin		:= 0
Private lQbCta		:= .T.
Private lxVAVRVT    := .f.
Private lxOutrBe    := .f.
Private lxPadrao    := .f.
Private lxPortal    := .f.
Private lx141142    := .f.
Private lxRVARVT    := .f.
Private lxVex       := .f.

PRIVATE aCnabSeq	:= {}	// Define a sequencia do pagamento por estagiário 

Default lAuto		:= .f.

//*************************************************************************
// VARIAVEIS UTILIZADAS PARA PARAMETROS                                
// mv_par01        //  Roteiros                                        
// mv_par02        //  Roteiros                                        
// mv_par03        //  Roteiros                                        
// mv_par04        //  Filial  De                                      
// mv_par05        //  Filial  Ate                                     
// mv_par06        //  Centro de Custo De                              
// mv_par07        //  Centro de Custo Ate                             
// mv_par08        //  Banco /Agencia De                               
// mv_par09        //  Banco /Agencia Ate                              
// mv_par10        //  Matricula De                                    
// mv_par11        //  Matricula Ate                                   
// mv_par12        //  Nome De                                         
// mv_par13        //  Nome Ate                                        
// mv_par14        //  Conta Corrente De                               
// mv_par15        //  Conta Corrente Ate                              
// mv_par16        //  Situacao                                        
// mv_par17        //  Layout                                          
// mv_par18        //  Arquivo de configuracao                         
// mv_par19        //  nome do arquivo de saida                        
// mv_par20        //  data de credito                                 
// mv_par21        //  Data de Pagamento De                            
// mv_par22        //  Data de Pagamento Ate                           
// mv_par23        //  Categorias                                      
// mv_par24        //  Imprimir 1-Funcionarios 2-Beneficiarias 3-Ambos 
// mv_par25        //  Data de Referencia                              
// mv_par26        //  Selecao de Processos                            
// mv_par27        //  Selecao de Processos                            
// mv_par28        //  SUBSTITUICO PELO NUMERO DO PEDIDO               
// mv_par29        //  Linha Vazia no Fim do Arquivo                   
// mv_par30        //  Processar Banco                                 
// mv_par31        //  Agencia				                            
// mv_par32        //  Conta				                            
// mv_par33        //  Gerar Conta Tipo                                
// mv_par34        //  DOC Outros Bancos                               
// mv_par28        //  Numero do Pedido                                
*************************************************************************

If cPaisLoc <> "MEX"
	If lNewPerg
		cCodBanco	:= mv_par30
		cCodAgenc	:= mv_par31
		cCodConta	:= mv_par32
		If cPaisLoc == "CHI"
			nTipoConta	:= mv_par33
			lGeraDOC  	:= mv_par34 == 1
		Else
			nTipoConta	:= mv_par33
			lGeraDOC  	:= mv_par34 == 1
		EndIf
	Else
		cCodBanco 	:= mv_par30
		cCodAgenc	:= mv_par31
		cCodConta	:= mv_par32
		nTipoConta	:= mv_par33
		lGeraDOC  	:= mv_par34 == 1
	EndIf
	lUsaBanco 	:= !Empty(cCodBanco)
	CTPOARCE 	:= IIF(cPaisLoc == "CHI" , mv_par33 , "" ) //Tipo Archivo Enviado
EndIf

lMod2Ambos	:= (nModelo == 2 .And. nTipoConta == 3)
lCCorrent 	:= (nTipoConta == 1) .Or. (lMod2Ambos)

/*Determina os tipos de contas permitidos*/
Do Case
	Case (nTipoConta == 1)
		cTpConta := " *1"
	Case (nTipoConta == 3)
		cTpConta := " *1*2"
	OtherWise
		cTpConta := "2"
EndCase

//Conforme ultima determinacao, so pode selecionar um roteiro. Caso tenha digitado mais que um roteiro, uma
//vez que o tamanho da pergunta permite, faz a validacao dessa limitacao
If len(cxRoteiros) > 3
	if lPgtoBA
		U_CJBK03LOG(2,"Foi digitado mais que um roteiro. Ajuste para que fique apenas um deles.","1")
	else
		If !_lJob
			Help( ,, 'HELP',, "Foi digitado mais que um roteiro. Ajuste para que fique apenas um deles.", 1, 0 ) 
		Endif
	endif	
	Return()
Endif  

//Limpa numeros dos pedidos quando for roteiro VTR e nao passou pela fOpcPed4
If cxRoteiros == 'VTR' .and. cTpBenInt == 'X'
	cQtdPedido := ''
EndIf

// AGRUPA OS PROCESSOS SELECIONADOS
If !(Empty(MV_PAR26 + MV_PAR27 )) //Processos para Impressao
	cProcessos:= AllTrim(MV_PAR26) + AllTrim(MV_PAR27) 
Else
	if lPgtoBA
		U_CJBK03LOG(2,"Nenhum processo foi informado.","1")
	else
		If !_lJob
			Help(" ",1,"GPEM80PROC") //P: Nenhum processo foi selecionado. ### S: Selecione ao menos um processo.
		Endif
	endif	
	Return()
EndIf  

if(lMod2Ambos .And. !lUsaBanco)
	if lPgtoBA
		U_CJBK03LOG(2,OemToAnsi(STR0036),"1")
	else
		/*Para gerar o arquivo para ambos os tipos de contas e necessario informar o codigo do banco da empresa.*/
		If !_lJob
			Help(,,OemToAnsi(STR0021),, OemToAnsi(STR0036),1,0 )
		Endif
	endif
	Return()
endIf

// CARREGANDO ARRAY AROTEIROS COM OS ROTEIROS SELECIONADOS
If Len(alltrim(MV_PAR01 + MV_PAR02 + MV_PAR03)) > 0
	SelecRoteiros()
	// caso o usuario nao digite o parametro mv_par01 e ja venha carregado com o conteudo anterior.
	If Empty(cxVerbas)
		BldafRoteiros()
	Endif
	// Caso nao seja alimentado o array aroteiros pela funcao SelectRoteiros eu adiciono manual pois esse array e usado no PE_gp410.prw 
	If Empty(aRoteiros)
		Aadd(aRoteiros, {Alltrim(MV_PAR01), "E", "", 7} )	
	Endif	
Else
	if lPgtoBA
		U_CJBK03LOG(2,"Nenhum roteiro foi informado. Informe ao menos um roteiro.","1")
	else
		If !_lJob
			Help( ,, 'HELP',, "Nenhum roteiro foi selecionado. Selecione ao menos um roteiro.", 1, 0 ) 
		Endif
	endif
	Return()
Endif  

If mv_par35 == 2
	if lPgtoBA
		U_CJBK03LOG(2,"Foi preenchido o parametro para gerar o arquivo com R$ 0.01.","1")
	else
		If !_lJob .And. ! MsgYesNo("Foi preenchido o parametro para gerar o arquivo com R$ 0.01 para validar as contas dos funcionarios. Deseja continuar ?", "Atencao")
			Return()
		Endif
	Endif
Else 
	// validacao para ter numero do pedido qdo selecionado os roteiros de VAVRVT e geracao dos valores dos beneficios e outros Beneficios.
	For nxRot:= 1 to len(cxRoteiros) step 3  
		cxRot:= Substr(cxRoteiros,nxRot,3) 
		If cxRot $ "VAL/VTR/VRF" .And. Empty(cQtdPedido)
			if lPgtoBA
				U_CJBK03LOG(2,"Foi selecionado um roteiro de VA/VR/VT","1")
			else
				If !_lJob		
					Help( ,, 'HELP',, "Foi selecionado um roteiro de VA/VR/VT, porem nao foi informado o numero do pedido. Informe ao menos um numero de pedido.", 1, 0 ) 
				ENDIF
			endif
			Return()
		Endif
		If cxRot $ "VAL/VTR/VRF" 
			lxVAVRVT:= .t.	
		Elseif cxRot == "BEN" 
			lxOutrBe:= .t.    
		Elseif cxRot $ "EST/FRE/VMS/DUC/ATM" 			
			lxPortal:= .t. 
			// verifica se existe a verba para buscar na tabela
			If (nPos := aScan(aVerbas,{|x| x[1] == cxRot })) > 0  
				cxVerbas+= alltrim(aVerbas[nPos,2]+aVerbas[nPos,3])
			Endif
			If Empty(cxVerbas)
				if lPgtoBA
					U_CJBK03LOG(2,"Nao foram encontradas as verbas correspondentes para geracao do roteiro especifico '"+cxRot+"' na tabela 'ZZR' ","1")
				else
					If !_lJob			
						Help( ,, 'HELP',, "Nao foram encontradas as verbas correspondentes para geracao do roteiro especifico '"+cxRot+"' na tabela 'ZZR' ", 1, 0 ) 
					ENDIF
				endif	
				Return()						
			Else
				cxVerbas:= fSqlIn(cxVerbas,3) 
			Endif 
		Elseif cxRot $ "141/142"
			lx141142:= .t.				
		Elseif cxRot $ "RVA/RVT"
			lxRVARVT := .t.
		Else
			lxPadrao:= .t.	
		Endif	
	Next
Endif   

/*
cArqAPS := "c:\temp\log_cnab"+cxRot+"_"+Dtos(Date())+".txt" 
cTexto  := "FILIAL ; MATRICULA ; VALOR " + Chr(13)+Chr(10)
nArqAPS := MsFCreate(cArqAPS)

If nArqAPS >  0
	lCriou:= .T.
Endif	 	
*/


If !Empty(MV_PAR01)
	cxRoteiros:= alltrim(MV_PAR01)
Endif	
/*
If !Empty(MV_PAR02)
	cxRoteiros+= alltrim(MV_PAR02)
Endif	   
If !Empty(MV_PAR03)
	cxRoteiros+= alltrim(MV_PAR03)
Endif
cxRoteiros  := fSqlIn(StrTran(cxRoteiros,'*'),3)
*/

//DEFINE SE DEVERA SER IMPRESSO FUNCIONARIOS OU BENEFICIARIOS
lImprFunci  := ( nFunBenAmb # 2 )
lImprBenef  := ( nFunBenAmb # 1 )

SA6->(dbSetOrder(1))

/*Trata o nome do arquivo*/
SetArqNome(@cArqSaida, @lCpyS2T,@cNomArq,@cNomDir)

if(lUsaBanco)
	/*E necessario obter as informacoes sobre o banco antes,
	dessa forma o cliente pode usar os dados no cabecalho.*/
	GetBankInf( lNewPerg,!lAuto  )
endIf

/*Valida a existencia do arquivo.
If	!(FILE(cArqEnt))
	Help(" ",1,"NOARQPAR")
	Return
Endif
*/
// MODIFICA VARIAVEIS PARA A QUERY
cSitQuery	:= fSqlIn(StrTran(cSituacao,'*'),1)
cCatQuery	:= fSqlIn(StrTran(cCategoria,'*'),1)
lAllProc	:= AllTrim( cProcessos ) == "*"
cNumPedido  := fSqlIn(StrTran(cQtdPedido,'*'),10)

If Empty(cSitQuery)
	aAdd( aLog, { OemToAnsi(STR0037) } ) //-- "Nao foi informada nenhuma Situacao nos parametros."
	cSitQuery := "''"
EndIF

If Empty(cCatQuery)
	aAdd( aLog, { OemToAnsi(STR0038) } ) //-- "Nao foi informada nenhuma Categoria nos parametros."
	cCatQuery := "''"
EndIF

If !lAllProc
	nTamCod := GetSx3Cache("RCJ_CODIGO", "X3_TAMANHO")
	cProcQuery := fSqlIn(cProcessos,nTamCod)
EndIf

cQuery := "SELECT R_E_C_N_O_ AS CHAVE, " + RetSqlName("SRA") + ".* "
cQuery += "FROM "+	RetSqlName("SRA")
cQuery += " WHERE RA_FILIAL BETWEEN '"  + cFilDe + "' AND '"  + cFilAte + "'"
cQuery += "AND RA_MAT BETWEEN '"        + cMatDe + "' AND '"  + cMatAte + "'"
cQuery += "AND RA_NOME BETWEEN '"       + cNomDe + "' AND '"  + cNomAte + "'"
cQuery += "AND RA_CC between '"         + cCcDe  + "' AND '"  + cCcate  + "'"
cQuery += "AND RA_CATFUNC IN ("         + Upper(cCatQuery)    + ")"
cQuery += "AND RA_SITFOLH IN ("         + Upper(cSitQuery)    + ")"

If mv_par35 == 2
	cQuery += "AND RA_ADMISSA BETWEEN '"+ Dtos(mv_par36) + "' AND '"+ Dtos(mv_par37) + "' "
	cQuery += "AND RA_XVALIBC = '1' "
Endif

If !lAllProc
	cQuery += "AND RA_PROCES IN("+ Upper(cProcQuery)+ ")"
EndIf

if IsInCallStack("U_CFINA94") //Se foi chamado pela rotina CNAB de inconsistencia, filtra apenas os registros com inconsistencia
	cQuery += "AND RA_FILIAL+RA_MAT IN ("+_cMatSel+")"
endif

cQuery += "   AND D_E_L_E_T_ <> '*'"

IF mv_par38 == 1

	cQuery += "   AND RA_XIDCONT NOT IN (SELECT ZCM_CODIGO FROM " + RetSqlName("ZCM") + " ZCM WHERE ZCM.D_E_L_E_T_='')"

ELSEIF mv_par38 == 2

	cQuery += "   AND RA_XIDCONT='"+ ZCM->ZCM_CODIGO +"'"
	//cQuery += "   AND RA_XIDLOCT='"+ ZCM->ZCM_LOCCTR +"'"
	cQuery += "   AND RA_XIDLOCT IN (SELECT ZR8_LOCCTR FROM " + RetSqlName("ZR8") + " ZR8 WHERE ZR8_CODIGO = '" + ZCM->ZCM_CODIGO + "' AND ZR8.D_E_L_E_T_='')"
	
ENDIF

If mv_par35 != 2
	cQuery	+= " AND RA_MAT IN (SELECT RD_MAT FROM " + RetSqlName("SRD") + " SRD WHERE SRD.D_E_L_E_T_='' AND RD_DATPGT='"+ DTOS(dDataPgto) +"')"
ENDIF	

cQuery	+= " ORDER BY RA_FILIAL, RA_MAT"

aStruSRA := SRA->(dbStruct())
SRA->( dbCloseArea() )

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SRA2")
//dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'SRA2', .F., .T.)

//Count To nTotalQ /*Conta a quantidade de registros retornados pela consulta.*/

If SRA2->(Eof())
	SRA2->(dbCloseArea())
	If !_lJob			
		Help( ,, 'SEM DADOS',, "Sem Dados para Processar. Verifique dados do Funcionario/Beneficiario.", 1, 0 ) 
	ENDIF
	Return
ENDIF


SRA2->(DbGoTop()) /*Retorna ao primeiro registro.*/

If !lAuto
	//oSelf:SetRegua1(nTotalQ) // Total de Elementos da regua
Endif

For nX := 1 To Len(aStruSRA)
	If ( aStruSRA[nX][2] <> "C" )
		TcSetField(cAliasSRA,aStruSRA[nX][1],aStruSRA[nX][2],aStruSRA[nX][3],aStruSRA[nX][4])
	EndIf
Next nX

//--------------------------------------------------------------------------------------------------------------------
//Tratamento para Quebra de Geração de Cnab por Nivel de Escolaridade - Não Misturar Nivel Superior com os demais
//ZCM =  Tabela de Geração de CNABS para Clientes Exclusivos
//Analisa antes se dentro do RecordSet da SRA existem contratos que consideram quebra de nivel de Escolaridade isto porque
//Podera ocorrer um misto de situações
ZCM->(dbSetOrder(1))
While SRA2->(!Eof())
	IF ZCM->(dbSeek(Xfilial("ZCM")+SRA2->(RA_XIDCONT + RA_XIDLOCT)))
		If ZCM->ZCM_QESCOL == "1"	//Quebra CNAB por nivel de escolaridade
			lpula:= .T.
			Exit
		Endif
	ENDIF
	SRA2->(dbSkip())
ENDDO
//----------------------------------------------------------------------------------------------------------------------

nQuebra:= If (lPula, 2,1)	 

For nNivel:= 1 To nQuebra  //Nivel 2 = Gera Somente Escolaridade Superior

	IF lPula .AND. nNivel==2
		cArqSaida:= mv_par19
	ENDIF

	SRA2->(DbGoTop()) /*Retorna ao primeiro registro.*/
	aValBenef:={}
	
	While SRA2->(!Eof())

		//Tratamento para Geração de Cnabs de Clientes Exclusivos
		IF ZCM->(dbSeek(Xfilial("ZCM")+SRA2->(RA_XIDCONT + RA_XIDLOCT)))

			If Type("LCNABEX") <> "L" //Significa que a Geração do CNAB não é Exclusiva, não veio da Opção do CFINA92 (Cnab Cliente)
				//Evita Gerar CNAB em duplicidade
				SRA2->(dbSkip())
				Loop
			ENDIF

			lAmarCtr:= .t.	//Não usar a SM0
			If ZCM->ZCM_QESCOL == "1"	//Quebra CNAB por nivel de escolaridade
				lpula:= .T.
			Endif
			
			ZC0->(DbSetOrder(1))
			ZC0->(dbSeek(Xfilial("ZC0")+ ZCM->ZCM_CODIGO ))

		ELSE
			lAmarCtr:= lAmarct2
		ENDIF

		//< 50 = Sem nível Superior
		If 	(lpula .And. SRA2->RA_GRINRAI < "50" .And. nNivel == 2) .Or.;	
			(lpula .And. SRA2->RA_GRINRAI >= "50" .And. nNivel == 1)
			SRA2->(dbSkip())
			Loop
		Endif

		//Posiciona na SRA Padrão
		SRA->(DbGoto(SRA2->CHAVE))

		// MOVIMENTA CURSOR
		If !lAuto
			oSelf:IncRegua1(IIF(cPaisLoc == "CHI", STR0035, STR0012) + "[" + SRA2->(RA_FILIAL + '/' + RA_MAT) + "]")
			If oSelf:lEnd
				Exit
			EndIf
		Endif
		nValor		:= 0
		aFunBenef	:= {}
		aRecnosSR0  := {}
		
		If SRA2->RA_FILIAL # FilAnt
			If !Fp_CodFol(@aCodFol,SRA2->RA_FILIAL)
				Exit
			Endif
			// Verifica Existencia da Tabela S052 - Bancos para CNAB
			If lUsaBanco
				GetBankInf( lNewPerg, !lAuto )
			EndIf
			FilAnt 	:= SRA2->RA_FILIAL
			lValidFil	:= .T.
			
			// CONSISTE FILIAIS E ACESSOS
			If !( SRA2->RA_FILIAL $ fValidFil() ) .or. !Eval( cAcessaSRA )
				SRA2->(dbSkip())
				lValidFil := .F.
				Loop
			EndIf
		EndIf
		
		// CONSISTE FILIAIS E ACESSOS
		If !lValidFil
			SRA2->(dbSkip())
			Loop
		EndIf

		//Filtro retirado para não gerar diferença entre a folha, cnab e titulo
		/*
		IF !U_CFILTSRA(.T.)
			SRA2->(dbSkip())
			Loop		
		ENDIF
		*/
		
		// BUSCA OS VALORES DE LIQUIDO E BENEFICIOS
		If lxPadrao
			//U_BuscaLiq(@nValor,@aFunBenef)
			Gp020BuscaLiq(@nValor,@aFunBenef)
		Else
			U_xBusLiqu(@nValor,@aFunBenef,@aRecnosSR0)
		Endif	
		
		// CONSISTE PARAMETROS DE BANCO E CONTA DO FUNCIONARIO
		If (SRA2->RA_BCDEPSA < cBcoDe) .Or. (SRA2->RA_BCDEPSA > cBcoAte) .Or.;
			(SRA2->RA_CTDEPSA < cCtaDe) .Or. (SRA2->RA_CTDEPSA > cCtaAte)
			nValor := 0
		EndIf
		
		// FILTRA GERACAO DE DOC'S
		If lUsaBanco
			lDocCc   := Left( SRA2->RA_BCDEPSA,3 ) <> cCodBanco .And. lCCorrent
			lDocPoup := Left( SRA2->RA_BCDEPSA,3 ) <> cCodBanco .And. !lCCorrent
			If !lGeraDoc .And. ( lDocCc .Or. lDocPoup )			
				nValor := 0
			ELSEIF lGeraDoc .and. cCodBanco == "237" .and. (Left(SRA2->RA_BCDEPSA,3)$"237|341|001|033|104")
				nValor := 0
				SRA2->(dbSkip(1))
				loop
			EndIf
		EndIf
		
		/*Se deve gerar funcionarios e valor maior que zero, adiciona o funcionario no vetor.*/
		If lImprFunci .And. nValor > 0
			aAdd(aFunBenef, {IIF(Empty(SRA2->RA_NOMECMP),SRA2->RA_NOME,SRA2->RA_NOMECMP),;
			SRA2->RA_BCDEPSA, SRA2->RA_CTDEPSA, "", nValor, SRA2->RA_CIC, SRA2->CHAVE, "SRA", IIf(cPaisLoc == "BRA",SRA2->RA_TPCTSAL, "")})
		EndIf
		
		// CONSISTE PARAMETROS DE BANCO E CONTA DO BENEFICIARIO
		// AFUNBENEF: 1-NOME  2-BANCO  3-CONTA  4-VERBA  5-VALOR  6-CPF
		If lUsaBanco
			If Len(aFunBenef) > 0
				/*Exclui do vetor possiveis beneficiarios que nao respeitem ao filtro ou
				funcionarios que tem o tipo de conta nao pertinente.*/
				while((nPos := aScan(aFunBenef,{|x|(X[2] < cBcoDe .Or. X[2] > cBcoAte) .Or. ;
					(X[3] < cCtaDe .Or. X[3] > cCtaAte) .Or. (!(X[9] $ cTpConta) .And. (cPaisLoc == "BRA"))})) > 0)
					aDel(aFunBenef,nPos)
					aSize(aFunBenef,Len(aFunBenef)-1)
				EndDo
			else
				SRA2->(dbSkip())
				Loop
			EndIf
		EndIf
		
		// Ponto de Entrada para desprezar somente o funcionario,somente o beneficiario ou ambos, utilizando o array aValBenef.
		// CNAB Modelos 1 e 2
		If lGp410Des
			If !(ExecBlock("GP410DES",.F.,.F.))
				SRA2->(dbSkip(1))
				Loop
			EndIf
		EndIf
		// SISPAG
		If lGp450Des
			If !(ExecBlock("GP450DES",.F.,.F.))
				SRA2->(dbSkip(1))
				Loop
			EndIf
		EndIf
		
		for nCntP:= 1 to Len(aFunBenef)
			/*Registros cujo campo TPCONTA estiverem vazios sao considerados Conta Corrente.*/
			if(Empty(aFunBenef[nCntP,9]))
				aFunBenef[nCntP,9] := '1'
			endIf
			aAdd(aFunBenef[nCntP],IIF((Left(aFunBenef[nCntP,2],3) == cCodBanco),cCodBanco,"DOC"))

			//Adiciona a posicao 11 com o aRecnosSR0 para posteriormente alterar o R0_PEDIDO
			aAdd(aFunBenef[nCntP],aRecnosSR0)

		next nCntP
		
		/*Adiciona ao vetor aFunBenef os registros que forem do proprio banco,
		os que nao forem(ou seja, sejam DOC), so sao adicionados se lGeraDoc for .T. e for
		utilizar um layout com multiplos lotes*/
		aEval(aFunBenef,{|x|IIF((lMod2Ambos .And. !lGeraDOC .And. Left(x[2],3) != cCodBanco) .Or. x[5] <= 0,/*Nao faz nada*/,aAdd(aValBenef,x))})
		aSize(aFunBenef,0)
		
		SRA2->( dbSkip( ) )
	Enddo

	ChkFile("SRA")
	dbSelectArea("SRA")/*O dbSelectArea reabre a tabela 'normal'*/
	SRA->(dbSetOrder(1))

	if(nModelo == 2 .And. Len(aValBenef) > 0)
		/*Ordena por forma de pagamento, utilizando o Banco + Agencia + TpContaSal + Matricula*/
		aSort(aValBenef,,,{|x,y|x[10] + x[2] + x[9] + STRZERO(x[7],GetSx3Cache("RA_MAT","X3_TAMANHO")) < y[10] + y[2] + y[9] + STRZERO(y[7],GetSx3Cache("RA_MAT","X3_TAMANHO"))})
		/*cLote e sempre: cCodBanco+TpContaSal OU 'DOC'+TpContaSal, sendo 'DOC' usado
		para qualquer outro banco diferente de cCodBanco.*/
		cLote := aValBenef[1,10] + aValBenef[1,9]
		/*Por padrao, ao chamar o HeadCnab2(pela funcao AbrePar), ela ja monta o cabecalho
		do primeiro lote.*/
		//HeadLote2(nHdlSaida,cArqent)
	endIf

	AtuNumdoc(aValBenef)

	If !lAuto .and. ! oSelf:lEnd
		// Apos concluida a consulta, cria o arquivo de saida.
		AbrePar(@cArqSaida,@cArqEnt,lAuto)
	ElseIf lAuto 
		// Apos concluida a consulta, cria o arquivo de saida.
		AbrePar(@cArqSaida,@cArqEnt,lAuto)
	Else
		Aviso(OemToAnsi(STR0039),OemToAnsi(STR0040), {OemToAnsi(STR0041)})
		Return
	EndIf

	If nModelo == 3 //SISPAG
		// ANALISA O TIPO DE BORDERO E DEFINE QUAIS HEADERS,TRAILLERS
		// E DETALHES DE LOTE QUE SERAO UTILIZADOS.
		//IDENTIFICADORES
		// A - HEADER ARQUIVO
		// B - HEADER  LOTE 1   HEADER LOTE CHEQUE/OP/DOC/CRED.CC
		// D - TRAILER LOTE 1   TRAILLER LOTE CHEQUE/OP/DOC/CRED.CC
		// F - TRAILER ARQUIVO
		// G - SEGMENTO A       CHEQUE/OP/DOC/CRED.CC
		// H - SEGMENTO B       INFORMACOES COMPLEMNTARES
		cHeadArq  := "A"
		cTraiArq  := "F"
		cHeadLote := "B"
		cTraiLote := "D"
		cDetaG    := "G"
		cDetaH    := "H"
		// GRAVA OS HEADERS DE ARQUIVO DE LOTE
		// OBSERVACAO: SERA' UM ARQUIVO PARA CADA BORDERO.
		U_GPM080Header( xFilial("SRA"), @cCodCnpj, @cNomeEmpr)
		U_fm080Linha(cHeadArq)
		U_fm080Linha(cHeadLote)
	EndIf

	For nCntP := 1 To Len(aValBenef)
		//Indica se o registro atual e o funcionario ou o beneficiario
		lRegFun := (aValBenef[nCntP,8] == 'SRA')
		
		//Posiciona no registro que esta sendo processado
		(aValBenef[nCntP,8])->(dbGoTo(aValBenef[nCntP,7]))
		
		if(!lRegFun) /*Se for Beneficiario, posiciona no Funcionario tambem.*/
			SRA->(dbSeek(SRQ->(RQ_FILIAL+RQ_MAT)))
		endIf
		
		cNome  := aValBenef[nCntP,1]
		cBanco := aValBenef[nCntP,2]
		cConta := aValBenef[nCntP,3]
		cCPF	:= aValBenef[nCntP,6]
		// VERIFICA VALOR E BANCO/AGENCIA DOS BENEFICIARIOS
		If aValBenef[nCntP,5] == 0 .Or. Empty(cBanco) .Or. cBanco < cBcoDe .Or. cBanco > cBcoAte
			Loop
		EndIf
		
		// IGUALA NAS VARIAVEIS USADAS DO ARQUIVO DE CADASTRAMENTO
		nValor := aValBenef[nCntP,5] * 100
		nTotal 	+= nValor
		nTotFunc++
		nSeq++
		
		// PONTO DE ENTRADA PARA ALTERAR DADOS CASO NECESSARIO
		If lGp450Val
			If !(ExecBlock("GP450VAL",.F.,.F.))
				Loop
			EndIf
		EndIf
		
		If ( nModelo == 1 )
			// LE ARQUIVO DE PARAMETRIZACAO
			nLidos:=0
			fSeek(nHdlBco,0,0)
			nTamArq:=FSEEK(nHdlBco,0,2)
			fSeek(nHdlBco,0,0)
			
			While nLidos <= nTamArq
				// VERIFICA O TIPO QUAL REGISTRO FOI LIDO
				xBuffer:=Space(85)
				FREAD(nHdlBco,@xBuffer,85)
				
				Do case
					Case SubStr(xBuffer,1,1) == CHR(1)
						If lHeader
							nLidos+=85
							Loop
						EndIf
					Case SubStr(xBuffer,1,1) == CHR(2)
						If !lFirst
							lFirst := .T.
							FWRITE(nHdlSaida,CHR(13)+CHR(10))
						EndIf
					Case SubStr(xBuffer,1,1) == CHR(3)
						nLidos+=85
						Loop
					Otherwise
						nLidos+=85
						Loop
				EndCase
				nTam := 1+(Val(SubStr(xBuffer,20,3))-Val(SubStr(xBuffer,17,3)))
				nDec := Val(SubStr(xBuffer,23,1))
				cConteudo:= SubStr(xBuffer,24,60)
				If ( aValBenef[ nCntP, 7 ] != 0 .and. ( SubStr(AllTrim(cConteudo),3,1) == "SRQ" ) )
					SRQ->(dbGoTo(aValBenef[nCntP,7]))
				EndIf
				lGrava := fM080Grava(nTam,nDec,cConteudo)
				If !lGrava
					Exit
				EndIf
				nLidos+=85
			EndDo
			If !lGrava
				Exit
			EndIf
		ElseIf ( nModelo == 2 )
			if(lMod2Ambos)
				if(cLote != aValBenef[nCntP,10] + aValBenef[nCntP,9]) .And. lQbCta
					nTotLin += nQtdLinLote + 2
					/*Encerra o Lote atual imprimindo seu Rodape(Trailer)*/
					RodaLote2(nHdlSaida,cArqent)
					/*Antes de imprimir o Header do Lote subsequente, incrementa o sequencial,
					zera o valor total e a quantidade de linhas do Lote.*/
					nLoteSeq++
					nLoteTotal		:= nValor
					nLoteQtd		:= 1 //Numero de Funcionarios
					cLote 			:= aValBenef[nCntP,10] + aValBenef[nCntP,9]
					nQtdLinLote	:= 0 //Numero de LINHAS, utilizado quando ha multiplos segmentos.
					HeadLote2(nHdlSaida,cArqent)
				else
					nLoteTotal	+= nValor
					nLoteQtd++
				endIf
			else
				nLoteTotal	+= nValor
				nLoteQtd++
			endIf
			
			lGrava := fM080Grava(,,)
		ElseIf ( nModelo == 3 )
			// GRAVA AS LINHAS DE DETALHE DE ACORDO COM O TIPO DO BORDERO
			u_fm080Linha( cDetaG ,@cLocaBco,@cLocaPro)
			U_fm080Linha( cDetaH ,@cLocaBco,@cLocaPro)
		EndIf
		If lGrava
			If ( nModelo == 1 )
				fWrite(nHdlSaida,CHR(13)+CHR(10))
				If !lHeader
					lHeader := .T.
				EndIf
			EndIf
			/*
			//Atualiza R0_PEDIDO para 2-Concluido
			For nZ := 1 to len(aValBenef[nCntP,11])
				SR0->(dbgoto(aValBenef[nCntP,11,nZ]))
				RecLock("SR0",.f.)
					SR0->R0_PEDIDO := '2'
				SR0->(MsUnLock())
			Next nZ
			*/
		EndIf
		//Grava arquivo de log.
		If nTotRegs == 0
			// 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123
			//"Processo          Filial          Matricula          Funcionario                             Liquido em Arquivo"
			// 12345             XX              123456             123456789012345678901234567890              999,999,999.99
			if cPaisLoc == "CHI"
				cLog := (Alltrim(STR0018)+ Space(03) + Alltrim(STR0019) + Space(nTamFil) + Alltrim(STR0023) + Space(04) + ;
				Alltrim(STR0017) + Space(Len(cNome)) + STR0035 )
			else
				cLog := (Alltrim(STR0019) + Space( 14 - nTamFil ) + STR0042 + Space(05) + Alltrim(STR0023) + Space(05) + Alltrim(STR0017) + Space(Len(cNome) - 10) + STR0012 )
				//						"Filial"							"Bco./Ag."					"Matricula"					"Funcionario"					"Liquido em Arquivo"
			endif
			
			Aadd(aTitle,cLog)
			Aadd(aLog,{})
			nTotRegs := len(aLog)
		EndIf
		if cPaisLoc == "CHI"
			Aadd(aLog[nTotRegs],(PADR(ALLTRIM(SRA->RA_PROCES),len(Alltrim(STR0018))+TAMSX3("RA_PROCES")[1], ) + PADR(ALLTRIM(SRA->RA_FILIAL),len(Alltrim(STR0019))+TAMSX3("RA_FILIAL")[1], ) +;
			PADR(ALLTRIM(SRA->RA_MAT),len(Alltrim(STR0023))+ TAMSX3("RA_MAT")[1], )+ PADR(ALLTRIM(cNome), TAMSX3("RA_NOMECMP")[1] , ) + PADL(alltrim(transform( (nValor / 100), "@E 999,999,999.99")),18, )))
			//"Processo " ### - "Filial " ### - "Matricula " ### - Funcionario " ### " - " + "Valor " ###.##
		else
			Aadd(aLog[nTotRegs], ( SRA->RA_FILIAL + Space( 12 - nTamFil ) + SRA->RA_BCDEPSA + Space(05) + SRA->RA_MAT + space(8) + cNome + space( 72 - Len(cNome) ) + Transform( (nValor / 100), "@E 999,999,999.99") ) )
			//Filial ######## - Banco/Agencia ######## - Matricula ###### - Nome ########## - Valor ###.##
		endif
		nRegsGrav++
		nTotVal += nValor
		gpm280Reset()
	Next nCntP

	If (nModelo == 1)
		// MONTA REGISTRO TRAILLER
		nSeq++
		nLidos:=0
		FSEEK(nHdlBco,0,0)
		nTamArq:=FSEEK(nHdlBco,0,2)
		FSEEK(nHdlBco,0,0)
		
		While nLidos <= nTamArq
			If !lGrava
				Exit
			EndIf
			// TIPO QUAL REGISTRO FOI LIDO
			xBuffer:=Space(85)
			fRead(nHdlBco,@xBuffer,85)
			If SubStr(xBuffer,1,1) == CHR(3)
				nTam := 1+(Val(SubStr(xBuffer,20,3))-Val(SubStr(xBuffer,17,3)))
				nDec := Val(SubStr(xBuffer,23,1))
				cConteudo:= SubStr(xBuffer,24,60)
				lGrava:=fM080Grava( nTam,nDec,cConteudo )
				If !lGrava
					Exit
				EndIf
			EndIf
			nLidos+=85
		EndDo
		If lGrava .And. lLnVazia
			fWrite(nHdlSaida,CHR(13)+CHR(10))
		EndIf
	ElseIf ( nModelo == 2 )
		nTotLin += nQtdLinLote + 4
		RodaCnab2(nHdlSaida,cArqent,lLnVazia)
	ElseIf ( nModelo == 3 )
		// GRAVA OS TRAILLERS DE LOTE E DE ARQUIVO
		U_fm080Linha(cTraiLote)
		U_fm080Linha(cTraiArq)
	EndIf

	// SE UTILIZAR TOTALIZADOR NO CABECALHO, TROCAR STRING POR VALOR
	If ExistBlock("GPM080HDR")
		ExecBlock("GPM080HDR",.F.,.F.)
	EndIf

	//PONTOS DE ENTRADAS UTILIZADOS PARA CRIPTOGRAFIA DE ARQUIVO DE ENVIO
	// CNAB Modelos 1 e 2
	If ExistBlock("GP410CRP")
		ExecBlock("GP410CRP",.F.,.F.)
	EndIf
	// SISPAG
	If ExistBlock("GP450CRP")
		ExecBlock("GP450CRP",.F.,.F.)
	EndIf

	fClose(nHdlSaida)
	fClose(nHdlBco)

	If lCpyS2T
		If CpyS2T( cStartPath + cNomArq, cNomDir)
			fErase( cStartPath + cNomArq )
		EndIf
	EndIf

	//Gera arquivo de log
	//Exibe apenas apos o fechamento do arquivo, pois caso contrario o arquivo fica preso ate
	//fecharem a tela de Log.
	If nTotRegs > 0
		Aadd(aLog[nTotRegs], Replicate("-",132))
		Aadd(aLog[nTotRegs], ( STR0024 + lTrim(Str(nRegsGrav,6))+ space(23) + STR0025 + Transform((nTotVal/100),"@E 999,999,999.99")) )
		//"Total de Registros Gerados: " ### "Valor Total: "
	Else
		lProcessado := .F.
		aAdd( aLog, { OemToAnsi(STR0026) } ) //"Nenhum Registro Processado com os Parametros Informados!"
	EndIf

	If lAuto
		IF IsInCallStack("U_CJOBK12")			
			aEval(aLog,{|x| AADD(_aLogCVb,x) })
			_aTitCVb:= ACLONE(aTitle)		
			msgAlert("Cnab gerado com sucesso")
		ELSE
			if lPgtoBA
				U_CJBK03LOG(2,"CNAB Gerado com sucesso","2")
				If !lCFIN92CN
					RECLOCK("RC1",.F.)
						RC1->RC1_XCNAB := cArqSaida
					MSUNLOCK()
				EndIf
			endif
		endif
	else 
		If lProcessado
			If !_lJob .And. MsgYesNo("O arquivo foi gerado no caminho: "+cArqSaida+ ". Deseja visualizar os movimentos ?", OemToAnsi(STR0021))	// "Deseja visualizar movimentos gerados?" ### "Atencao!"
				cData	:=	DtoS(DDATABASE)
				cHora	:=	Time()
				cArq := "GPM080" + cData
				fMakeLog (aLog,aTitle,,.T.,cArq,IIF(cPaisLoc == "CHI", STR0034 , STR0022),"M","P",,.F.)	//	"Log de Geracao de Liquidos em Arquivo." 
			//    For nx:=1 to Len(aLog)
			//		cTexto += aLog[nx]
			//		fWrite(nArqAPS,cTexto) 
			//	Next	
	
			EndIf
		Else
			If !_lJob
				MsgInfo("Nenhum registro processado com os parâmetros informados!", "Atenção")
			Else
				ConOut("Nenhum registro processado com os parâmetros informados!")
			EndIf
		EndIf
	EndIf     
	/*
	If lCriou
		fClose(nArqAPS)
	Endif
	*/
Next

SRA2->(dbCloseArea())

Return

/*
*************************************************************************
*Funcao    *AbrePar   * Autor * Wagner Xavier         * Data * 26/05/92 *
*************************************************************************
*Descricao *Abre arquivo de Parametros                                  *
*************************************************************************
*Sintaxe   *AbrePar()                                                   *
*************************************************************************
* Uso      *GPEM080                                                     *
*************************************************************************
*/
Static Function AbrePar(cArqSaida,cArqEnt,lAuto)

If ( nModelo == 1 .Or. nModelo == 3 )
	nHdlBco:=FOPEN(cArqEnt,0+64)
EndIf

// PONTOS DE ENTRADAS PARA ALTERAR O NOME DA VARIAVEL CARQSAIDA
// CNAB MODELOS 1 E 2
/*
If ExistBlock("GP410ARQ")
	cArqSaida := ExecBlock( "GP410ARQ", .F., .F., {cArqSaida} )
EndIf
*/
//cArqSaida :=  XGP410AR()
cArqSaida :=  XGP410AR(lAuto)
// SISPAG
If ExistBlock("GP450ARQ")
	cArqSaida := ExecBlock( "GP450ARQ", .F., .F., {cArqSaida} )
EndIf

// CRIA ARQUIVO SAIDA
If ( nModelo == 1 .or. nModelo == 3 )
	nHdlSaida:=MSFCREATE(cArqSaida,0)
Else
	nHdlSaida:=HeadCnab2(cArqSaida,cArqent)
EndIf

Return .T.

/*
*************************************************************************
*Funcao    *fM080Grava* Autor * Wagner Xavier         * Data * 26/05/92 *
*************************************************************************
*Descricao *Rotina de Geracao do Arquivo de Remessa de Comunicacao      *
*          *Bancaria                                                    *
*************************************************************************
*Sintaxe   *ExpL1:=fM080Grava(ExpN1,ExpN2,ExpC1)                        *
*************************************************************************
* Uso      * GPEM080                                                    *
*************************************************************************
*/
STATIC Function fM080Grava( nTam,nDec,cConteudo )
Local lConteudo := .T., cCampo

If ( nModelo == 1 .or. nModelo == 3 )
	// ANALISA CONTEUDO
	If Empty(cConteudo)
		cCampo:=Space(nTam)
	Else
		If "_ARQ" $ cConteudo
			gpm280Var(cConteudo)
		EndIf
		lConteudo := fM080Orig( cConteudo )
		If !lConteudo
			Return .F.
		Else
			If ValType(xConteudo)="D"
				cCampo := GravaData(xConteudo,.F.)
			ElseIf ValType(xConteudo)="N"
				cCampo:=Substr(Strzero(xConteudo,nTam,nDec),1,nTam)
			Else
				cCampo:=Substr(xConteudo,1,nTam)
			EndIf
		EndIf
	EndIf
	If Len(cCampo) < nTam  //Preenche campo a ser gravado, caso menor
		cCampo:=cCampo+Space(nTam-Len(cCampo))
	EndIf
	Fwrite( nHdlSaida,cCampo,nTam )
Else
	DetCnab2(nHdlSaida,cArqent)
EndIf

Return lConteudo

/*
*************************************************************************
*Funcao    *fM080Orig* Autor * Wagner Xavier         * Data * 26/05/92  *
*************************************************************************
*Descricao *Verifica se expressao e' valida para Remessa CNAB.          *
*************************************************************************
* Uso      * GPEM080                                                    *
*************************************************************************
*/
Static Function fM080Orig( cForm )
Local bBlock:=ErrorBlock()
//Local bErro := ErrorBlock( { |e| ChecErr260(e,cForm) } )
Private lRet := .T.

BEGIN SEQUENCE
xConteudo := &cForm
END SEQUENCE

ErrorBlock(bBlock)

Return lRet

/*
*************************************************************************
*Funcao    *fm080Linha* Autor * Wagner Xavier         * Data * 26/05/92 *
*************************************************************************
*Descricao *letra correspondente  * linha do arquivo de Sispag          *
*************************************************************************
* Uso      * GPEM080                                                    *
*************************************************************************
*/
User Function fm080Linha( cParametro ,cLocaBco , cLocaPro)
Local nLidos    := 0
Local nTamArq   := 0
Local nTam      := 0
Local nDec      := 0
local cConteudo := ""
Local lGerouReg := .F.

cLocaBco := If(Empty(cLocaBco),"",cLocaBco)
cLocaPro := If(Empty(cLocaPro),"",cLocaPro)

If ValType( cParametro ) # "C" .or. Empty( cParametro )
	Return .T.
EndIf

// LE ARQUIVO DE PARAMETRIZACAO
nLidos := 0
fSeek(nHdlBco,0,0)
nTamArq := fSeek(nHdlBco,0,2)
fSeek(nHdlBco,0,0)

While nLidos <= nTamArq
	// VERIFICA O TIPO QUAL REGISTRO FOI LIDO
	xBuffer := Space(85)
	fRead(nHdlBco,@xBuffer,85)
	
	If SubStr( xBuffer,1,1) == cParametro
		nTam := 1+(Val(SubStr(xBuffer,20,3))-Val(SubStr(xBuffer,17,3)))
		nDec := Val(SubStr(xBuffer,23,1))
		cConteudo := SubStr(xBuffer,24,60)
		If ( STR0009== SubStr(xBuffer,2,15) .Or.; //"Codigo Banco   "
			STR0010==SubStr(xBuffer,2,15) .Or.;  //"Num. Agencia   "
			STR0011==SubStr(xBuffer,2,15) )      //"Num. C/C.      "
			If (!SubStr(xBuffer,2,15)$cLOCAPRO )
				cLOCABCO += &(ALLTRIM(cConteudo))
				cLOCAPRO += SubStr(xBuffer,2,15)
			EndIf
		EndIf
		If (("CGC"$Upper(SubStr(xBuffer,2,15)) .And.	AllTrim(cConteudo)=='"16670085000155"' ) .Or. cLOCABCO=="34101403000000034594")
			if lPgtoBA
				U_CJBK03LOG(2,"Configuração inválida","1")
			else
				If !_lJob		
					Alert("CONFIGURACAO INVALIDA")
				ENDIF
			endif	
			lGrava := .F.
		Else
			lGrava := fM080Grava(nTam,nDec,cConteudo)
		EndIf
		If !lGrava
			Exit
		EndIf
		lGerouReg := .T.
	EndIf
	
	nLidos += 85
	
EndDo

If lGerouReg
	FWRITE(nHdlSaida,CHR(13)+CHR(10))
EndIf

Return

/*
*************************************************************************
*Funcao    *FDLiqu* Autor * RH                        * Data * 26/05/92 *
*************************************************************************
*Descricao *SELECIONAR DIRETORIO PARA GRAVA ARQUIVO CNAB/SISPAG         *
*************************************************************************
* Uso      * GPEM080                                                    *
*************************************************************************
*/

User Function FDLiqu(cLayout)
//Local mvRet		:= Alltrim(ReadVar())
Local cType 	:= ""
Local cArq		:= ""
Local aDir		:= {}
Local nDir		:= 0

cType := If(cLayout == 1, ".CPE|*.CPE|.REM|*.REM|", If(cLayout == 2, "" , STR0015)) //" PAG |PAG "

// COMANDO PARA SELECIONAR UM ARQUIVO.
// PARAMETRO: GETF_LOCALFLOPPY - INCLUI O FLOPPY DRIVE LOCAL.
//            GETF_LOCALHARD - INCLUI O HARDDISK LOCAL.
cArq 	:= cGetFile(cType, OemToAnsi(STR0016), 0,, .T.,GETF_LOCALHARD+GETF_LOCALFLOPPY,,)  // "Selecione arquivo "
aDir	:= { { cArq } }

For nDir := 1 To Len(aDir)
	cArq := aDir[nDir][1]
	
	If !Empty(cArq)
		If !File(cArq)
			if lPgtoBA
				U_CJBK03LOG(2,OemToAnsi(STR0030)+ cArq,"1")
			else
				If !_lJob				
					MsgAlert(OemToAnsi(STR0030)+ cArq)  // "Arquivo nao encontrado "
				ENDIF
			endif
			Return .F.
		EndIf
	EndIf
Next nDir

&mvRet := cArq

Return (.T.)

/*
*************************************************************************
*Funcao    *DetCnab2* Autor * RH                        * Data * 26/05/92 *
*************************************************************************
*Descricao *Geracao do arquivo na rotina local devido o tratamento das  *
*          *variaveis disponibilizadas para geracao do arquivo liquidos *
*************************************************************************
* Uso      * GPEM080                                                    *
*************************************************************************
*/
Static Function DetCnab2(nHandle,cLayOut,lIdCnab,cAlias)
Local nHdlLay	:= 0
Local lContinua := .T.
Local cBuffer	:= ""
Local aLayOut	:= {}
Local aDetalhe  := {}
Local nCntFor	:= 0
Local nCntFor2  := 0
Local lFormula  := ""
Local nPosIni	:= 0
Local nPosFim	:= 0
Local nTamanho  := 0
Local nDecimal  := 0
Local bBlock	:= ErrorBlock()
//Local bErro 	:= ErrorBlock( { |e| ChecErr260(e,xConteudo) } )
Local aGetArea  := GetArea()
Local cIdCnab
Local aArea
Local nOrdem

DEFAULT cAlias 	:= ""
DEFAULT lIdCnab 	:= .F.
Private xConteudo := ""

nQtdLinLote := If(Type("nQtdLinLote") != "N",0,nQtdLinLote)

If ( File(cLayOut) )
	nHdlLay := FOpen(cLayOut,64)
	While ( lContinua )
		cBuffer := FreadStr(nHdlLay,502)
		If ( !Empty(cBuffer) )
			If ( SubStr(cBuffer,1,1)=="1" )
				If ( SubStr(cBuffer,3,1) == "D" )
					aadd(aLayOut,{ SubStr(cBuffer,02,03),;
					SubStr(cBuffer,05,30),;
					SubStr(cBuffer,35,255)})
				EndIf
			Else
				If ( SubStr(cBuffer,3,1) == "D" )
					aadd(aDetalhe,{SubStr(cBuffer,02,03),;
					SubStr(cBuffer,05,15),;
					SubStr(cBuffer,20,03),;
					SubStr(cBuffer,23,03),;
					SubStr(cBuffer,26,01),;
					SubStr(cBuffer,27,255)})
				EndIf
			EndIf
		Else
			lContinua := .F.
		EndIf
	End
	FClose(nHdlLay)
EndIf
If nHandle > 0
	For nCntFor := 1 To Len(aLayOut)
		Begin Sequence
		lFormula := &(AllTrim(aLayOut[nCntFor,3]))
		If ( lFormula .And. SubStr(aLayOut[nCntFor,1],2,1)=="D" )
			cBuffer := ""
			// So gera outro identificador, caso o titulo ainda nao o tenha, pois pode ser um re-envio do arquivo
			If !Empty(cAlias) .And. lIdCnab .And. Empty((cAlias)->&(Right(cAlias,2)+"_IDCNAB"))
				// Gera identificador do registro CNAB no titulo enviado
				nOrdem := If(Alltrim(Upper(cAlias))=="SE1",16,11)
				cIdCnab := GetSxENum(cAlias, Right(cAlias,2)+"_IDCNAB",Right(cAlias,2)+"_IDCNAB"+cEmpAnt,nOrdem)
				// Garante que o identificador gerado nao existe na base
				dbSelectArea(cAlias)
				aArea := (cAlias)->(GetArea())
				dbSetOrder(nOrdem)
				While (cAlias)->(MsSeek(xFilial(cAlias)+cIdCnab))
					ConOut("Id CNAB " + cIdCnab + " ja existe para o arquivo " + cAlias + ". Gerando novo numero ")
					If ( __lSx8 )
						ConfirmSX8()
					EndIf
					cIdCnab := GetSxENum(cAlias, Right(cAlias,2)+"_IDCNAB",Right(cAlias,2)+"_IDCNAB"+cEmpAnt,nOrdem)
				EndDo
				(cAlias)->(RestArea(aArea))
				Reclock(cAlias)
				(cAlias)->&(Right(cAlias,2)+"_IDCNAB") := cIdCnab
				MsUnlock()
				ConfirmSx8()
				lIdCnab := .F. // Gera o identificacao do registro CNAB apenas uma vez no
				// titulo enviado
			EndIf
			For nCntFor2 := 1 To Len(aDetalhe)
				If ( aDetalhe[nCntFor2,1] == aLayOut[nCntFor,1] )
					xConteudo := aDetalhe[nCntFor2,6]
					If ( Empty(xConteudo) )
						xConteudo := ""
					Else
						If "_ARQ" $ xConteudo
							gpm280Var(xConteudo)
						EndIf
						xConteudo := &(AllTrim(xConteudo))
					EndIf
					nPosIni   := Val(aDetalhe[nCntFor2,3])
					nPosFim   := Val(aDetalhe[nCntFor2,4])
					nDecimal  := Val(aDetalhe[nCntFor2,5])
					nTamanho  := nPosFim-nPosIni+1
					Do Case
						Case ValType(xConteudo) == "D"
							xConteudo := GravaData(xConteudo,.F.)
						Case ValType(xConteudo) == "N"
							xConteudo := StrZero(xConteudo,nTamanho,nDecimal)
					EndCase
					xConteudo := SubStr(xConteudo,1,nTamanho)
					xConteudo := PadR(xConteudo,nTamanho)
					cBuffer += xConteudo
				EndIf
			Next nCntFor2
			cBuffer += Chr(13)+Chr(10)
			Fwrite(nHandle,cBuffer,Len(cBuffer))
			nQtdLinLote++
		EndIf
		End Sequence
	Next nCntFor
	ErrorBlock(bBlock)
EndIf
RestArea(aGetArea)
Return(.T.)

Static Function gpm280Var(xConteudo)
Return()

STATIC FUNCTION gpm280Reset()
CIC_ARQ		:= ""
NOME_ARQ	:= ""
PRINOME_ARQ	:= ""
SECNOME_ARQ	:= ""
PRISOBR_ARQ	:= ""
SECSOBR_ARQ	:= ""
BANCO_ARQ	:= ""
CONTA_ARQ	:= ""
Return()
/*/{Protheus.doc} User Function GPM080Header
	Retorna dados para a Foramação do Arquivo de Remessa Cnab
	Chamada pelo Arquivos de Configurações de CNAB HEADER ou Pela função deste Fonte.
	@type  Function
	@author Luiz Enrique
	@since 07/05/2020
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function GPM080Header(cFil,cCodCnpj,cNomeEmpr,nTipo)

Local lxRet		:= .T.	
Local lamarracao:= .F.
Local cReturn	:= ""
Local aOldAtu	:= GetArea()
Local aOldSm0	:= SM0->(GetArea())
Local aOldZC0	:= ZC0->(GetArea())

Local npos		:= 0	
Local cHorario 	:= ""
Local cHora 	:= ""
Local cMinut	:= "" 
Local cSegun	:= "" 
Local cHorRet	:= "000000"
//Local cXNumDoc	:= Space(20)
//Local cXDTREFE  := "" 
//Local cXCnabSeq := "" 

Default cFil	:= xFilial("SM0")
Default nTipo	:= 0

//Tratamento CNAB Exclusivo para Clientes da ZCM
If Type("lAmarCtr") == "L" .And. lAmarCtr
	lamarracao:= .t.
ENDIF

IF nTipo == 0	//Chamada oriunda do Proprio fonte. Quando Chamada dos arquivos CNABS de configuração, então nTipo > 0

	If !(lAmarCtr)
		DbSelectArea("SM0")
		DbSetOrder(1)
		If dbSeek(cEmpAnt + cFil)
			cCodCnpj  := SM0->M0_CGC
			cNomeEmpr := Upper(Alltrim(SM0->M0_NOMECOM))
		EndIf
	ENDIF

	fInfo(@aInfo,cFil)

ENDIF

If lxRet
	Do CASE
		CASE nTipo == 1		//Retorna CNPJ
			IF lamarracao
				cReturn:= 	ZC0->ZC0_NUMDOC
			ELSE
				cReturn:= 	SM0->M0_CGC
			ENDIF
		CASE nTipo == 2		//Nome da Empresa
			IF lamarracao
				cReturn:= 	Upper(ZC0->ZC0_NOME)
			ELSE
				cReturn:= 	Upper(SM0->M0_NOMECOM)
			ENDIF
		CASE nTipo == 3		//Retorna Inscrição
			IF lamarracao
				cReturn:= 	ZC0->ZC0_NUMDOC
			ELSE
				cReturn:= 	SM0->M0_CGC
			ENDIF
		CASE nTipo == 4		//Retorna LOGRADOURO 
			IF lamarracao
				cReturn:= 	Upper(Alltrim(ZC0->ZC0_LOGEMP)) + " " + Upper(Alltrim(ZC0->ZC0_ENDEMP))  + " " + Upper(Alltrim(ZC0->ZC0_NUMEMP))
			ELSE
				cReturn:= 	Upper(SM0->M0_ENDCOB)
			ENDIF
		CASE nTipo == 5		//Retorna COMPLEMENTO 
			IF lamarracao
				cReturn:= 	Upper(Alltrim(ZC0->ZC0_COMEMP))
			ELSE
				cReturn:= 	Upper(SM0->M0_COMPCOB)
			ENDIF
		CASE nTipo == 6		//Retorna CIDADE 
			IF lamarracao
				cReturn:=	Upper(ZC0->ZC0_CIDEMP)
			ELSE
				cReturn:= 	Upper(SM0->M0_CIDCOB)
			ENDIF
		CASE nTipo == 7		//Retorna CEP 
			IF lamarracao
				cReturn:=	Upper(ZC0->ZC0_CEPEMP)
			ELSE
				cReturn:=	Upper(SM0->M0_CEPCOB)
			ENDIF                         
		CASE nTipo == 8		//Retorna ESTADO
		IF lamarracao
				cReturn:=	Upper(ZC0->ZC0_ESTEMP)
			ELSE
				cReturn:= 	Upper(SM0->M0_ESTCOB)
			ENDIF 
		CASE nTipo == 9		//Retorna o Horario Atual 

			cHorario:= Time()										
			npos:= At(":",cHorario)
			If npos > 0 
				//Obtem a Hora
				cHora:= Substr(cHorario,1,npos-1) 
				cHora:= Strzero(Val(cHora),2)
				cHorario:= Substr(cHorario,npos+1)
				//Obtem os minutos 
				npos:= At(":",cHorario)
				cMinut:= Substr(cHorario,1,npos-1) 
				cMinut:= Strzero(Val(cMinut),2)
				cHorario:= Substr(cHorario,npos+1)
				//Obtem os Segundos
				cSegun:= Strzero(Val(cHorario),2)

				cHorRet:= cHora + cMinut + cSegun
			Endif
				
			cReturn:= cHorRet

		CASE nTipo == 10		//Retorna a formação do Numero do Documento

			//Define a sequencia do pagamento por estagiário			
			/*npos:= AsCan(aCnabSeq,{|x|x[1] == SRA->RA_XID }) 
			If nPos > 0	//Existe Sequencia Anterior ???
				cXCnabSeq:= Soma1(aCnabSeq [npos,2])
         		aCnabSeq [npos,2]:= cXCnabSeq
			Else		//Inicializa a Sequencia
				cXCnabSeq:= "01"
				Aadd(aCnabSeq,{ SRA->RA_XID,"01" })	
      		Endif

			REGRA PARA NUMERO DO DOCUMENTO: 	LIMITE DA COLUNA DO ARQUIVO DE ESTRUTURA CNAB: 20 bytes
			Nº documento = 
			Codigo estagiário -						(08 caracteres) (SRA->RA_XID )  + 
			Data de Referencia -					(06 caracteres) (AAMMDD) + 
			Sequencia do Pagamento por estagiário 	(02 caracteres) (cXCnabSeq). Mais de um pagto para mesmo favorecido no caso BA e VT +
			Sequencial do arquivo - 				(04 caracteres) (CSEQ) . 
			Argumentação do Usuario. -----> 		No SOE não gerava, mas adotamos isso no novo processo, ajuda a identificar o arquivo. 
													Esse campo caso fique igual 1;2;3 pagto, paga o 1º e rejeita os demais por considerar duplicidade.
			
			cXDTREFE:= DTos(dDataPgto)
			cReturn:= SUBSTR(Substr(SRA->RA_XID,1,8) + SUBSTR(cXDTREFE,3,6) + cXCnabSeq + CSEQ ,1,20)*/
			cReturn := LEFT(U_CGPEV08F() + SPACE(20),20) 			
			 
	ENDCASE   

ENDIF

RestArea(aOldSm0)
RestArea(aOldZC0)
RestArea(aOldAtu)

Return cReturn

USER Function CNABSeq()
Local cSTabela   := "S052"
Local aOldAtu   := GetArea()
Local cRet      := "000000"
Local cTexto    := ""
Local cRCCAlias := GetNextAlias()
Local nUltSeq   := 0

//Default cTipo := ''

If lUsaBanco
	
	BeginSql Alias cRCCAlias
		SELECT  R_E_C_N_O_ as RECNO, substring(RCC_CONTEU,43,6) as SEQ FROM	%table:RCC% RCC
		WHERE RCC.RCC_CODIGO   = %Exp:(cSTabela)%  AND RCC.%NotDel% and
		      substring(RCC_CONTEU,21,3) = %Exp:cCodBanco%
	EndSql

	While (cRCCAlias)->(!Eof()) 
		nUltSeq := max(nUltSeq,val((cRCCAlias)->SEQ))
		(cRCCAlias)->(dbSkip())
	EndDo
			
	nUltSeq++
	
	If nUltSeq > 999
		nUltSeq := 1
	EndIf
	cRet   := StrZero(nUltSeq,3)
			
	(cRCCAlias)->(dbgotop())

	While (cRCCAlias)->(!Eof()) 
	
		RCC->(DbGoto( (cRCCAlias)->RECNO ))
		cTexto := Stuff(RCC->RCC_CONTEU,43,6,cRet+Space(3))	
		RecLock("RCC",.F.)
			RCC->RCC_CONTEU := cTexto
		MsUnlock()
			
		(cRCCAlias)->(dbSkip())
	EndDo
	
	(cRCCAlias)->(DBCloseArea())
EndIf

RestArea( aOldAtu )

Return( cRet )

/*/{Protheus.doc} GetBankInf
Obtem os dados sobre o banco selecionado pelo usuario
@author philipe.pompeu
@since 22/06/2016
@version P11
@return ${return}, ${return_description}
/*/
Static Function GetBankInf( lNewPerg, lShowHelp, cFilBco, cFilDe ) 
Local aTabS052  := {}
Local _lRet 	:= .T.
Begin Sequence
	Default lNewPerg  := .F. 
	DeFault lShowHelp := .T.
	Default cFilBco   := XFILIAL("SEE")  //SRA->RA_FILIAL
	Default cFilDe	  := Space(Len(SEE->EE_FILIAL))	

	fCarrTab( @aTabS052, "S052", Nil,,,,cFilBco)
//	If Len( aTabS052 ) == 0 .Or. ( nPos := aScan(aTabS052,{|x| AllTrim(x[6]) == cCodBanco .And. IIf( lNewPerg .And. cPaisLoc <> "MEX",(AllTrim(x[7]) == cCodAgenc .And. AllTrim(x[9]) == cCodConta),.T. ) .and. (Empty(x[2]) .or. x[2] == If(! Empty(cFilDe), cFilDe, cFilBco))}) ) == 0
	If Len( aTabS052 ) == 0 .Or. ( nPos := aScan(aTabS052,{|x| x[6] == cCodBanco .And. IIf( lNewPerg .And. cPaisLoc <> "MEX",(x[7] == cCodAgenc .And. x[9] == cCodConta),.T. ) .and. (Empty(x[2]) .or. x[2] == If(! Empty(cFilDe), cFilDe, cFilBco))}) ) == 0
	   If lShowHelp
			if lPgtoBA
				U_CJBK03LOG(2,STR0031,"1")
			else
				If !_lJob					   
	   				Aviso(STR0021,STR0031,{STR0032}) //"ATENCAO","Banco e Filial para processamento do CNAB nao cadastrados na tabela S052! Favor verificar!" ### Sair
				ENDIF
			endif   
	   EndIf
	   _lRet := .F.
	   Break
	EndIf
	U_GPM080Header( cFilBco, @cCodCnpj, @cNomeEmpr)
   	cCodFilial := aTabS052[nPos,2]
	cCodConve  := aTabS052[nPos,5]
	cCodAgenc  := aTabS052[nPos,7]
	cDigAgenc  := aTabS052[nPos,8]
	cCodConta  := aTabS052[nPos,9]
	cDigConta  := aTabS052[nPos,10]
	cSeq       := aTabS052[nPos,11]

    If cPaisLoc == "BRA" .And. Len( aTabS052[nPos] ) >= 12
		lQbCta := aTabS052[nPos,12] == "S"
	EndIf
	SA6->(dbSeek( xFilial("SA6",cFilBco) + cCodBanco + cCodAgenc + cCodConta ))
End Begin	
Return _lRet


/*/{Protheus.doc} SetArqNome
Trata o nome do arquivo.
@author philipe.pompeu
@since 22/06/2016
@version P11
@param cArqSaida, character, (Descricao do parametro)
@param lCpyS2T, ${param_type}, (Descricao do parametro)
@param cNomArq, character, (Descricao do parametro)
@param cNomDir, character, (Descricao do parametro)
@return ${return}, ${return_description}
/*/
Static Function SetArqNome(cArqSaida,lCpyS2T,cNomArq,cNomDir)
Local nTpRemote	:= 0
Local nAt			:= 0
Local cNewArq		:= ""
Local cAux			:= ""
Local nCont		:= 1
Default cArqSaida := ""
Default lCpyS2T := .F.
Default cNomArq := ""
Default cNomDir := ""
/*
|VERIFICA SE O USUARIO DEFINIU UM DIRETORIO LOCAL PARA GRAVACAO DO ARQ. |
|DE SAIDA, POIS NESSE CASO EFETUA A GERACAO DO ARQUIVO NO SERVIDOR E AO |
|FIM DA GERACAO COPIA PARA O DIRETORIO LOCAL E APAGA DO SERVIDOR.       |
*/
If Substr(cArqSaida, 2, 1) == ":"
	
	//?-CHECA O SO DO REMOTE (1=WINDOWS, 2=LINUX)
	nTpRemote := (GetRemoteType())
	
	If nTpRemote = 2
		nAt := RAt("/", cArqSaida)
	Else
		nAt := RAt("\", cArqSaida)
	EndIf
	
	If nAt = 0
		//"O ENDERECO ESPECIFICADO NO PARAMETRO 'ARQUIVO DE SAIDA' NAO E VALIDO. DIGITE UM ENDERECO VALIDO CONFORME O EXEMPLO:"
		//"UNIDADE:\NOME_DO_ARQUIVO"#"/NOME_DO_ARQUIVO"
		if lPgtoBA
			U_CJBK03LOG(2,STR0027 +  If(nTpRemote = 1, STR0028, STR0029),"1")
		else
			If !_lJob					 		
				Alert(STR0027 + CRLF + CRLF + If(nTpRemote = 1, STR0028, STR0029))
			ENDIF
		endif
		Return
	EndIf
	
	cNewArq := cArqSaida
	
	If (cAux := Substr(cArqSaida, Len(cArqSaida), 1)) == " "
		While cAux == " "
			cNewArq	:= Substr(cArqSaida, 1, Len(cArqSaida) - nCont)
			cAux	:= Substr(cNewArq, Len(cNewArq), 1)
			nCont++
		EndDo
	EndIf
	
	cNomArq		:= Right(cNewArq, Len(cNewArq) - nAt)
	cNomDir		:= Left(cNewArq, nAt)
	
	cArqSaida	:= cStartPath + cNomArq
	lCpyS2T		:= .T.
Endif
Return nil

/*============================================================================================================
 Funcao para buscar o total dos beneficios que serao pagos via CNAB, ou seja, poderao ter varios calculos e caso
 seja o mesmo numero de pedido sera algutinado em um valor so.
@author     A.Shibao
@since      12/11/18
@param
@version    P12
@return
@project
@client    Ciee
@campos
//============================================================================================================*/ 
User Function xBusLiqu(nValor,aValBenef,aRecs)

//Local aArea   := GetArea() 
Local cxQuery := ""
Local cQAlias := GetNextAlias() 
Local nCntP,nRoteiro
Local aCodBenef:= {}

nValor := 0
// condicao para gerar o arquivo bancario para todas pessoas com 0.01 
If mv_par35 == 2
	
	nValor := 0.01
	
	//Adiciona beneficiário para validação
	IF lImprBenef	
		
		For nRoteiro := 1 to Len(aRoteiros)
			fBusCadBenef(@aCodBenef,aRoteiros[nRoteiro, 1],, .T.) 
			For nCntP := 1 To Len(aCodBenef)
				Aadd(aValBenef, {  aCodBenef[nCntP,09],  aCodBenef[nCntP,10], aCodBenef[nCntP,11], "", nValor,aCodBenef[nCntP,12],aCodBenef[nCntP,19],"SRQ", If(Len(aCodBenef[nCntP]) >= 22, aCodBenef[nCntP,22], ""),aCodBenef[nCntP,23],aCodBenef[nCntP,24] } ) 
			Next
		Next	
		
		IF !(lImprFunci)
			nValor:= 0
		ENDIF		

	ENDIF	

	Return()
Endif

// VTR/VAL/VRF
If lxVAVRVT // "VTR/VAL/VRF" $ !Empty(cNumPedido) 

	cxQuery := "SELECT R0_VALCAL, R_E_C_N_O_ FROM  "+RetSqlName('SR0')+" SR0 "
	cxQuery += "WHERE SR0.D_E_L_E_T_ = '' "
	cxQuery += "AND R0_FILIAL = '" + SRA->RA_FILIAL + "' "
	cxQuery += "AND R0_MAT    = '" + SRA->RA_MAT    + "' "
	cxQuery += "AND R0_NROPED IN (" + cNumPedido + ") "
	cxQuery += "AND R0_ROTEIR = '" + cxRoteiros + "' "

	If !empty(cTpBenInt) .and. cxRoteiros == 'VTR'
		cxQuery += "  AND ( right(R0_NROPED,2) <> '01' or "
		cxQuery +=        " right(R0_NROPED,2) = '01' and R0_TPBEN in ("+cTpBenInt+") ) "
	Else
		cxQuery += "  AND right(R0_NROPED,2) <> '01' "
	EndIf
	
	dbUseArea( .T., "TOPCONN", TcGenQry( ,, cxQuery ), cQAlias , .F., .T. )
	
	While (cQAlias)->(!eof())
	
		nValor += (cQAlias)->R0_VALCAL
		aadd(aRecs,(cQAlias)->R_E_C_N_O_)
		
		(cQAlias)->(dbskip())
		
	EndDo
	
	(cQAlias)->(DbCloseArea())       
	
Endif


// OUTROS BENEFICIOS     
If lxOutrBe //!Empty(MV_PAR21) .And. Empty(cNumPedido)

	cQAlias := GetNextAlias()
	cxQuery:= ""
	cxQuery := "SELECT SUM(RIQ_VALCAL) AS LIQUIDO FROM  "+RetSqlName('RIQ')+" RIQ "
	cxQuery += "WHERE RIQ.D_E_L_E_T_ = '' "
	cxQuery += "AND RIQ_FILIAL = '" + SRA->RA_FILIAL + "' "
	cxQuery += "AND RIQ_MAT    = '" + SRA->RA_MAT    + "' "
	cxQuery += "AND RIQ_PERIOD IN ('" + SUBSTR(DTOS(MV_PAR21),1,6) + "') "
	
	dbUseArea( .T., "TOPCONN", TcGenQry( ,, cxQuery ), cQAlias , .F., .T. )
	
	nValor += (cQAlias)->LIQUIDO
	
	(cQAlias)->(DbCloseArea()) 
Endif   

// EST/FRE/VMS/DUC/ATM
If lxPortal   

	cxQuery := "SELECT SUM(RGB_VALOR) AS LIQUIDO FROM  "+RetSqlName('RGB')+" RGB "
	cxQuery += "WHERE RGB.D_E_L_E_T_ = '' "
	cxQuery += "AND RGB_FILIAL = '" + SRA->RA_FILIAL + "' "
	cxQuery += "AND RGB_MAT    = '" + SRA->RA_MAT    + "' "
	cxQuery += "AND RGB_DTREF >= '" + DTOS(dDataDe)  + "' "
	cxQuery += "AND RGB_DTREF <= '" + DTOS(dDataAte) + "' "	
	cxQuery += "AND ( SUBSTRING(RGB_NUMID,17,3) = '" + ALLTRIM(MV_PAR01) + "' "
   	cxQuery += "      OR RGB_PD IN ("+cxVerbas+")   "		
   	cxQuery += "     ) "
	
	dbUseArea( .T., "TOPCONN", TcGenQry( ,, cxQuery ), cQAlias , .F., .T. )
	
	nValor := (cQAlias)->LIQUIDO
	
	(cQAlias)->(DbCloseArea())       
	
Endif     

// 141 E 142
If lx141142 

	nValor:= u_fSearch14()

Endif

// RVA/RVT - Reemissao VA e VT - quando efetivado o credito solicitado pelo pedido padrao e precisa gerar cnab
If lxRVARVT  

	cxQuery := "SELECT SUM(RGB_VALOR) AS LIQUIDO FROM  "+RetSqlName('RGB')+" RGB "
	cxQuery += "WHERE RGB.D_E_L_E_T_ = '' "
	cxQuery += "AND RGB_FILIAL = '" + SRA->RA_FILIAL + "' "
	cxQuery += "AND RGB_MAT    = '" + SRA->RA_MAT    + "' "
	If cxRoteiros == 'RVA'
		cxQuery += "AND RGB_PD in ('C93','D04') "		
	ElseIf cxRoteiros == 'RVT'
		cxQuery += "AND RGB_PD in ('C94','D03') "		
	EndIf
	cxQuery += "AND RGB_DTREF >= '" + DTOS(dDataDe)  + "' "
	cxQuery += "AND RGB_DTREF <= '" + DTOS(dDataAte) + "' "	
	cxQuery += "AND RGB_ROTEIR = 'FOL' "	
	
	dbUseArea( .T., "TOPCONN", TcGenQry( ,, cxQuery ), cQAlias , .F., .T. )
	
	nValor := (cQAlias)->LIQUIDO
	
	(cQAlias)->(DbCloseArea())       
	
Endif


Return()

/*==================================================================================================
  Monta a lista de opcoes com os 5 ultimos pedido calculados para selecao.
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee
//================================================================================================== */
User Function fOpcPed4() 

Local MvPar
//Local nX
Local MvParDef := ""
Local aItens   := {}
Local aArea    := GetArea()
Local lRet     := .t.
//Local nCont    := 1  
Local lMultiplo:=.F. 
Local nTabC

If !Empty(MV_PAR01)
	cxRoteiros:= alltrim(MV_PAR01)
Endif	
/*
If !Empty(MV_PAR02)
	cxRoteiros+= alltrim(MV_PAR02)
Endif	   
If !Empty(MV_PAR03)
	cxRoteiros+= alltrim(MV_PAR03)
Endif
cxRoteiros  := fSqlIn(StrTran(cxRoteiros,'*'),3)
*/

If len(cxRoteiros) > 3
	lMultiplo:= .t.   
	cRot1:= Substr(cxRoteiros,1,3)
Else
	cRot1:= cxRoteiros
Endif

MvPar := &(Alltrim(ReadVar()))       // Carrega Nome da Variavel do Get em Questao
MvRet := Alltrim(ReadVar())          // Iguala Nome da Variavel ao Nome variavel de Retorno 

If cRot1 == 'VTR'

	aTabS011  := {}
	cTpBenInt := ''

	// carrega tabela com Tipos de Beneficios.
	fCarrTab( @aTabS011,"S011",Nil)
	
	//Busca os beneficios com o fornecedor 008-CIEE (interno)
	For nTabC:= 1 to len(aTabS011)
		If cEmpAnt == '40' .and. aTabS011[nTabC,7] == '008'
			cTpBenInt += "'"+aTabS011[nTabC,5]+"'"
		Endif	
	Next
EndIf


/*
cQuery := ""
cQuery += " SELECT DISTINCT(R0_NROPED),R0_ROTEIR FROM " + RETSQLNAME("SR0")+ " "
cQuery += " WHERE R0_NROPED >= ( SELECT MAX(R0_NROPED) FROM "+ RETSQLNAME("SR0")+ " "
cQuery += "                      WHERE D_E_L_E_T_  = ''  AND R0_ROTEIR IN ('"+cRot1+"')  "
cQuery += "                     ) - 5  "
cQuery += " AND D_E_L_E_T_  = ''  AND R0_ROTEIR  IN ('"+cRot1+"')  "    
*/
cQuery := ""
cQuery += "  SELECT DISTINCT TOP 5 (R0_NROPED),R0_ROTEIR, R0_ANOMES, R0_PEDIDO, R0_TPBEN " 
cQuery += "  FROM "+ RETSQLNAME("SR0")+ " WHERE D_E_L_E_T_  = ''                "
cQuery += "  AND R0_ROTEIR IN ('"+cRot1+"')  									"
cQuery += "  AND SUBSTRING(R0_FILIAL,7,2) = '"+cxFil+"'							"
If !empty(cTpBenInt) .and. cRot1 == 'VTR'
	cQuery += "  AND ( right(R0_NROPED,2) <> '01' or "
	cQuery +=        " right(R0_NROPED,2) = '01' and R0_TPBEN in ("+cTpBenInt+") ) "
Else
	cQuery += "  AND right(R0_NROPED,2) <> '01' "
EndIf

/*
If lMultiplo
	For nx:= 4 to len(cxRoteiros) Step 3
		cRot2 := Substr(cxRoteiros,nx,3) 
		
	    //cQuery += " UNION "
		//cQuery += " SELECT DISTINCT(R0_NROPED),R0_ROTEIR FROM " + RETSQLNAME("SR0")+ " "
		//cQuery += " WHERE R0_NROPED >= ( SELECT MAX(R0_NROPED) FROM "+ RETSQLNAME("SR0")+ " "
		//cQuery += "                      WHERE D_E_L_E_T_  = ''  AND R0_ROTEIR IN ('"+cRot2+"')  "
		//cQuery += "                     ) - 5  "
		//cQuery += " AND D_E_L_E_T_  = ''  AND R0_ROTEIR  IN ('"+cRot2+"')  "  
		       
	    cQuery += " UNION "	 
		cQuery += " SELECT DISTINCT TOP 5 (R0_NROPED),R0_ROTEIR, R0_ANOMES, R0_PEDIDO FROM " + RETSQLNAME("SR0")+ " "	    	
		cQuery += " WHERE D_E_L_E_T_  = ''                "   
		cQuery += " AND R0_ROTEIR IN ('"+cRot2+"')  									"
		cQuery += " AND SUBSTRING(R0_FILIAL,7,2) = '"+cxFil+"'							"		
		cQuery += " AND right(R0_NROPED,2) <> '01' "
	Next	
Endif
*/

cQuery += " ORDER BY R0_ROTEIR, R0_NROPED DESC"

cQuery := ChangeQuery(cQuery)

//Verifica se Tabela Aberta
If Select("OMULT") > 0
	DbSelectArea("OMULT")
	OMULT->(DbCloseArea())
EndIf

//Abre Tabela
dbUseArea( .T., 'TOPCONN', TcGenQry( ,, cQuery ), "OMULT", .T., .F. )

OMULT->(DbGotop())

While !Eof()  
	If !empty(cTpBenInt) .and. OMULT->R0_TPBEN $ cTpBenInt
		aAdd(aItens, OMULT->R0_ROTEIR + " - " +  OMULT->R0_ANOMES + " (Interno "+OMULT->R0_TPBEN+")" )
	Else
		aAdd(aItens, OMULT->R0_ROTEIR + " - " +  OMULT->R0_ANOMES )
	EndIf
	MvParDef += OMULT->R0_NROPED   //cvaltochar(nCont++)
	dbSkip()
Enddo

//         Retorno,Titulo              ,opcoes ,Strin Ret,lin,col, Tipo Sel,tam chave , n. ele ret, Botao
IF Empty(mv_par28)
   f_Opcoes(@MvPar, "Ultimos 5 Pedidos de cada roteiro - AnoMes ", aItens, MvParDef, 12, 49, .f., 10, 5)  // "Opcoes"
   &MvRet := STRTRAN(mvpar,"*","")
ElseIf !( MvParDef $ mv_par28 )
	If !_lJob
    	MsgAlert("Nao existe esse numero de pedido na base de dados. Favor ajustar para o numero valido !")
	Endif
    //f_Opcoes(@MvPar, "Ultimos 5 Pedidos", aItens, MvParDef, 12, 49, .f., 10, 1)  // "Opcoes"
    //&MvRet := mvpar
    lret:= .f.
Endif

RestArea(aArea)                                  // Retorna Alias

Return lret


/*============================================================================================================
 Funcao para listar apenas os roteiros que serao gerados pela rotina customizada.
@author     A.Shibao
@since      12/11/18
@param
@version    P12
@return
@project
@client    Ciee
@campos
//============================================================================================================*/ 
User Function fxLisRot( l1Elem , cPreSelect ) 

Local aNewSelect		:= {}
Local aPreSelect		:= {}
Local cFilSRY			:= xFilial("SRY")
Local cTitulo			:= ""
//Local cReadVar			:= ""
Local MvParDef			:= ""
Local MvRetor			:= ""
Local MvParam			:= ""
Local lRet				:= .T.
Local nFor				:= 0
Local nAuxFor			:= 1
Local MvPar     		:= NIL

DEFAULT cPreSelect		:= ""
DEFAULT l1Elem			:= .F.

Begin Sequence

	cAlias 	:= Alias()
	MvPar	:= &(Alltrim(ReadVar()))
	mvRet	:= Alltrim(ReadVar())

	If AllTrim( MvPar ) == "*"
		Break
	EndIf

	CursorWait()
		For nFor := 1 To Len( cPreSelect ) Step 3
			aAdd( aPreSelect , SubStr( cPreSelect , nFor , 3) )
		Next nFor

		If !( l1Elem )
			For nFor := 1 TO Len(alltrim(MvPar))
				Mvparam += PADR( (Subs(MvPar,nAuxFor,3)), 3 )
				MvParam += Replicate("*",3)
				nAuxFor := (nFor * 3) + 1
			Next
		Endif
		mvPar 	:= MvParam
		
		afRoteiros	:= BldafRoteiros( cFilSRY )
		
	CursorArrow()
	
	IF !( lRet := !Empty( afRoteiros ) )
		if lPgtoBA
			U_CJBK03LOG(2,"Nao existe esse roteiro para a filial","1")
		else
			If !_lJob		
				Help(" ",1,"Nao existe esse roteiro para a filial")	
			ENDIF
		endif	
		Break
	EndIF	
    
	CursorWait()
		For nFor := 1 To Len( afRoteiros )
			IF ( aScan( aPreSelect , SubStr( afRoteiros[ nFor ] , 1 , 3 ) ) == 0.00 )
				MvParDef+=Left(afRoteiros[ nFor ],3)
				aAdd( aNewSelect , afRoteiros[ nFor ] )
			EndIF
		Next nFor
	CursorArrow()
	
	// ajustado para o usuario selecionar apenas um roteiro.
	IF f_Opcoes(@MvPar,cTitulo,aNewSelect,MvParDef,12,49,l1Elem,3,1)
		CursorWait()
			For nFor := 1 To Len( mVpar ) Step 3
				IF ( SubStr( mVpar , nFor , 3 ) # "***" ) 
					mvRetor += SubStr( mVpar , nFor , 3)  
				Endif
			Next nFor
			&MvRet := Alltrim(Mvretor)
			If &MvRet == ""
				&MvRet := Space(30)
			EndIf
		CursorArrow()	
	EndIF

End Sequence

dbSelectArea(cAlias)

Return( lRet )       

/*============================================================================================================
 Funcao para listar a tabela SRY para o filtro
@author     A.Shibao
@since      12/11/18
@param
@version    P12
@return
@project
@client    Ciee
@campos
//============================================================================================================*/ 
Static Function BldafRoteiros( cFilSRY )

Local aArea		:= GetArea()  
//Local cFilZZR	:= xFilial("ZZR") 
//Local aQuery	:= {} 
Local cQuery	:= {} 
Local aRoteiros	:= {}  

//Local bSkip		:= { || aAdd( aRoteiros , ( RY_CALCULO + " - " + RY_DESC ) ) , .F. }
//Local bSkip2	:= { || aAdd( aRoteiros , ( ZZR_IDENTI + " - " + ZZR_DESC ) ) , .F. }

Default cFilSRY	:= xFilial("SRY")

cQuery := ""
cQuery += "  SELECT RY_CALCULO,RY_FILIAL,RY_DESC,RY_ALIAS AS VERBAMES,RY_ALIAS AS VERBAANT, R_E_C_N_O_  " 
cQuery += "  FROM "+ RETSQLNAME("SRY")+ " WHERE D_E_L_E_T_  = ''                "
cQuery += "  AND RY_FILIAL='"+cFilSRY+"'"									    "

/*
cQuery += "  UNION "
cQuery += "  SELECT DISTINCT(ZZR_IDENTI) AS RY_CALCULO,ZZR_FILIAL AS RY_FILIAL,  ZZR_DESC AS RY_DESC , ZZR_VBALAN AS VERBMES, ZZR_VBAANT AS VERBAANT, R_E_C_N_O_   "
cQuery += "  FROM "+ RETSQLNAME("ZZR")+ " WHERE D_E_L_E_T_  = ''                "  
cQuery += "  AND ZZR_IDENTI NOT IN (SELECT RY_CALCULO FROM "+ RETSQLNAME("SRY")+ " WHERE D_E_L_E_T_  = '' )        "
cQuery += "  AND ZZR_IDENTI <> ' ' AND ZZR_FILIAL ='"+cFilZZR+"'" 
*/

cQuery := ChangeQuery(cQuery)

//Verifica se Tabela Aberta
If Select("OSRMZZ") > 0
	DbSelectArea("OSRMZZ")
	OSRMZZ->(DbCloseArea())
EndIf

//Abre Tabela
dbUseArea( .T., 'TOPCONN', TcGenQry( ,, cQuery ), "OSRMZZ", .T., .F. )

OSRMZZ->(DbGotop())

While !Eof()  
	aAdd(aRoteiros, Alltrim(OSRMZZ->RY_CALCULO) + " - " +  Alltrim(OSRMZZ->RY_DESC) )
	If Empty( aVerbas ) 
		aAdd(aVerbas  , {Alltrim(OSRMZZ->RY_CALCULO), OSRMZZ->VERBAMES, OSRMZZ->VERBAANT} ) 	
	Elseif !(nPos := aScan(aVerbas,{|x| x[1] == OSRMZZ->RY_CALCULO .And. x[2] == OSRMZZ->VERBAMES })) > 0
		aAdd(aVerbas  , {Alltrim(OSRMZZ->RY_CALCULO), OSRMZZ->VERBAMES, OSRMZZ->VERBAANT} ) 		
	Endif	
	dbSkip()
Enddo

//Acrescenta os roteiros Virtuais RVA e RVT para considerar verba de Base importada na RGB para pagamento em CNAB
//referente a beneficios que nao foram creditados por algum motivo de bloqueio de cartao
aAdd(aRoteiros  ,"RVA - Reemissao VA/VR" ) 		
aAdd(aRoteiros  ,"RVT - Reemissao VT" ) 		

RestArea(aArea)
Return(aClone(aRoteiros))  

/*============================================================================================================
 Funcao para retornar o banco + agencia + banco para os parametros.
@author     Totvs
@since      12/11/18
@param
@version    P12
@return
@project
@client    Ciee
@campos
//============================================================================================================*/ 
User Function GP052SXB( cTabela, cCpoRet, cFiltro, cCpo2, lFilial )
Local aArea		:= GetArea()
Local nOpca:=0, i,lAllOk
Local oDlg, cCampo, nX, nY, cCaption, cPict, cValid, cF3, cWhen, nLargSay, oSay, oGet
//Local uConteudo
//Local nLargGet
Local cBlkGet,cBlkWhen,cBlkVld, oSaveGetdad := Nil, aSvRot := Nil
Local oTop
//Local oBottom
Local aObject := {}
Local aSize := {}
Local nObject
//Local nAuxWidth := 0
Local aCordW := {125,0,450,635}
Local cSvField	:= &(ReadVar())
Local nCount := 0
//Local cMyCpo := ""
//Local lDelGetD := .F.
Local cLineOk := "AllwaysTrue()"
Local cAllOk  := "AllwaysTrue()"
Local nOpcx	:= 7
Local aCGD	:= {}
Local lExist := .F.
Local nCpoRet := 0
Local cPesq := Space(30)
Local nCntCmb := 0
Local nMaxCmb := 5	//# Nr.Maximo de opcoes no Combo
Local nPos 		:= At("+", cCpoRet )
Local cCpoAux	:= ""
Local cRcbCampo	:= ""
Local cRcbDescr	:= ""
//Local cRetFiltro:= ""
Local cDescr	:= ""
Private cCombo  := ""
Private aCombo  := {}
Private aMyCombo:= {}
Private aSXBCols   := {}
Private aSXBHeader := {}
Private nUsado  := 0

Private cFilRCB  := ""
Private cFilRCC  := ""
Private cDescRCC := ""
Private lPesqComp := .F. //Variavel que indica se a pesquisa esta sendo feita com mais de um campo

Default cFiltro := ""
Default cCpo2	:= ""
Default lFilial	:= .T.

If cTabela == NIL .Or. cCpoRet == NIL
	if lPgtoBA
		U_CJBK03LOG(2,"Nao foi possivel continuar, pois faltam parametros nesta funcao","1")
	else
		If !_lJob		
			MsgAlert(OemToAnsi("Nao foi possivel continuar, pois faltam parametros nesta funcao !!!"),OemToAnsi("Atencao !"))	
		Endif
	endif	
	Return(.F.)
EndIf

If nPos > 0
	lPesqComp := .T.
EndIf

//# Posiciona no RCB
dbSelectArea("RCB")
dbSetOrder(1)

If !dbSeek(xFilial("RCB")+cTabela,.F.)
	if lPgtoBA
		U_CJBK03LOG(2,"A Tabela "+cTabela+" não existe na RCB","1")
	else
		If !_lJob	
			MsgAlert(OemToAnsi("A Tabela informada nao existe !!!"),OemToAnsi("Atencao !"))	
		ENDIF
	endif
	Return(.F.)
EndIf

cFilRCB  := xFilial("RCB")
cDescRCC := Alltrim(RCB_DESC)

//# Posiciona no RCC
dbSelectArea("RCC")
dbSetOrder(1)

If !ExistRTab(cTabela)//!dbSeek(xFilial("RCC")+cTabela,.F.)
	if lPgtoBA
		U_CJBK03LOG(2,"Não existem informações cadastradas na tabela "+cTabela ,"1")
	else
		If !_lJob
			MsgAlert(OemToAnsi("Nao existem informacoes cadastradas na tabela ") + cTabela,OemToAnsi("Atencao !") )		
		Endif
	ENDIF
	Return(.F.)
EndIf

//-- Verifica se foi chamado pela funcao GPEM080 e filtra os resultados pelos parametros informados na rotina
If IsInCallStack("CGPER04")

	RCC->(dbSeek(xFilial( "RCC" ) + cTabela))
	
	While !RCC->(Eof()) .And. (RCC->RCC_FILIAL + RCC->RCC_CODIGO == xFilial( "RCC" ) + cTabela)
	
		If !Empty(RCC->RCC_FIL) .And. RCC->RCC_FIL >= MV_PAR04 .AND. RCC->RCC_FIL <= MV_PAR05
			cFiltro := {|| (RCC->RCC_FIL >= MV_PAR04 .AND. RCC->RCC_FIL <= MV_PAR05)  }
			Exit
		Else 
			cFiltro := {|| (Empty(RCC->RCC_FIL))  }
		EndIf
		RCC->(DbSkip())
	EndDo
	lFilial	:= .F.
EndIf

cFilRCC := xFilial("RCC")

fMontaHeaderRCC( cTabela, cCpoRet )
MontaColsRCC( cTabela, cCpoRet, , cFiltro, lFilial )

//# Variaveis inicializadas no teste
Private cTitulo := cTabela+" - "+cDescRCC //#"U014 - Teste"
Private nMax := Len(aSXBCols)
Private aC := {}
Private aColsBkp := aClone(aSXBCols)

//# Variaveis inicializadas no teste
aAdd(aC,{"cMyCpo", {15,001},"",,,,.F.,})

nCount++
__cLineOk := cLineOK
__nOpcx	 := nOpcx
If nCount > 1
	oSaveGetdad := oGetDados
	oSaveGetdad:oBrowse:lDisablePaint := .t.
EndIf

oGets := {}
If Type("aRotina") == "A"
	aSvRot := aClone(aRotina)
EndIf

aRotina := {}
For nX := 1 to nOpcX
	AADD(aRotina,{"","",0,nOpcx})
Next

aCGD:=Iif(Len(aCGD)==0,{34,5,128,315},aCGD)

DEFINE MSDIALOG oDlg TITLE OemToAnsi(cTitulo) FROM aCordW[1],aCordW[2] TO aCordW[3],aCordW[4] PIXEL OF oMainWnd

If Len(aC) > 0
	
	//# Monta o Combo a partir do Titulo do RCB
	dbSelectArea("RCB")
	dbSeek(xFilial("RCB")+cTabela,.F.)
	
	While !Eof() .And. RCB->(RCB_FILIAL+RCB_CODIGO) == (cFilRCB+cTabela)

		//# Verifica se o campo ja existe
		If !lExist .And. ValType("RCB->RCB_PESQ")<>"U"
			lExist := .T.
		EndIf
		
		//# Monta o aCombo e aMyCombo
		If !lExist .Or. (lExist .And. RCB->RCB_PESQ=="1")
			nCntCmb += 1
			aAdd( aCombo	, Alltrim(Capital(RCB_DESCPO)) )
			aAdd( aMyCombo, {Alltrim(Capital(RCB_DESCPO)),Alltrim(RCB_CAMPOS)} )
			If lPesqComp .And. At(Alltrim(RCB_CAMPOS), cCpoRet) > 0
				cRcbDescr += Alltrim(Substr(Capital(RCB_DESCPO),1,9)) + '+'
				cRcbCampo += Alltrim(RCB_CAMPOS) + '+'
			EndIf
			If nCntCmb >= nMaxCmb
				Exit
			EndIf
		EndIf
		dbSkip()
	EndDo
	If lPesqComp
		cRcbDescr := Substr(cRcbDescr, 1, Len(cRcbDescr)-1)
		cRcbCampo := Substr(cRcbCampo, 1, Len(cRcbCampo)-1)
		nCntCmb += 1
		aAdd( aCombo, Alltrim(cRcbDescr) )
		aAdd( aMyCombo, {Alltrim(cRcbDescr),Alltrim(cRcbCampo)} )
	EndIf       

	dbSelectArea("RCC")
	
	oTop:= TPanel():Create(oDlg,01,102,"",,.F.,,,,100,100)	
	
	Aadd(aSize,aCGD[1]+16)
	Aadd(aObject,oTop)
	nObject := 2
	
	Private oCombo, oPesq, oBtn1, oCheckBox, lCheck
	
	@ 003,005 SAY OemToAnsi("Pesquisar por: ") SIZE 35,10 OF oTop PIXEL	// "Pesquisar por: "
	@ 010,005 MSCOMBOBOX oCombo VAR cCombo ITEMS aCombo SIZE 125,12 OF oTop PIXEL
	@ 010,140 CHECKBOX oCheckBox VAR lCheck PROMPT OemToAnsi("Ordenar") VALID Iif(!Empty(cCombo),GP310Ord(),fValPesq()) SIZE 55,10 OF oTop PIXEL	// "Ordenar"
	@ 010,180 MSGET oPesq VAR cPesq PICTURE "@!" VALID Iif(!Empty(cCombo),PesqDados(cPesq),fValPesq()) SIZE 115,10 OF oTop PIXEL
	@ 021,585 BTNBMP oBtn1 RESOURCE "FWSKIN_ICON_LOOKUP" SIZE 025,025 OF oTop PIXEL ACTION ( PesqDados(cPesq) )
	
	For i:=1 to Len(aC)
		cCampo:=aC[i,1]
		nX:=aC[i,2,1]-13
		nY:=aC[i,2,2]
		cCaption:=Iif(Empty(aC[i,3])," ",aC[i,3])
		cPict:=Iif(Empty(aC[i,4]),Nil,aC[i,4])
		cValid:=Iif(Empty(aC[i,5]),".t.",aC[i,5])
		cF3:=Iif(Empty(aC[i,6]),NIL,aC[i,6])
		cWhen    := Iif(aC[i,7]==NIL,".t.",Iif(aC[i,7],".t.",".f."))
		cWhen    := Iif(!(Str(nOpcx,1,0)$"346"),".f.",cWhen)
		cBlKSay  := "{|| OemToAnsi('"+cCaption+"')}"
		
		oSay     := TSay():New( nX+1, nY, &cBlkSay,oTop,,, .F., .F., .F., .T.,,,,, .F., .F., .F., .F., .F. )
		nLargSay := GetTextWidth(0,cCaption) / 1.8  // estava 2.2
		cCaption := oSay:cCaption
		
		cBlkGet  := "{ | u | If( PCount() == 0, "+cCampo+","+cCampo+":= u ) }"
		cBlKVld  := "{|| "+cValid+"}"
		cBlKWhen := "{|| "+cWhen+"}"
					
		oGet := TGet():New( nX, nY+nLargSay,&cBlKGet,oTop,,,cPict, &(cBlkVld),,,, .F.,, .T.,, .F., &(cBlkWhen), .F., .F.,, .F., .F. ,cF3,(cCampo))
		AADD(oGets,oGet)
	Next
EndIf

oGetDados := MsNewGetDados():New(aCGD[1],;// nTop
								 aCGD[2],;   	// nLelft
								 aCGD[3],;	// nBottom
	                             aCGD[4],;	// nRright
								 nOPCX,;	    	// controle do que podera ser realizado na GetDado - nstyle
								 "SXBMod2LOk()",;	// funcao para validar a edicao da linha - ulinhaOK
								 "AllwaysTrue()",;	// funcao para validar todas os registros da GetDados - uTudoOK
  								 NIL,;				// cIniCPOS
								 NIL,;		        // aAlter
								 0,; 				// nfreeze
								 nMax,;  			// nMax
								 NIL,;		 		// cFieldOK
								 NIL,;				// usuperdel
								 .F.,;	        	// udelOK
								 @oDlg,;        	// objeto de dialogo - oWnd
								 @aSXBHeader,;		// Vetor com Colunas - AparHeader
								 @aSXBCols;			// Vetor com Header - AparCols
					)

Aadd(aObject,oGetDados:oBrowse)
Aadd(aSize,NIL)

ACTIVATE MSDIALOG oDlg CENTERED ON INIT (EnchoiceBar(oDlg,{||nOpca:=1,lAllOk:=__Mod2OK(cAllOk),;
											 IIF(lAllOk,oDlg:End(),nOpca:=0)},{||oDlg:End()},,),;
											 AlignObject(oDlg,aObject,1,nObject,aSize),oGetDados:oBrowse:Refresh())

nCount--
If nCount > 0
	oGetDados := oSaveGetDad
	oGetDados:oBrowse:lDisablePaint := .f.
EndIf
If ValType(aSvRot) == "A"
	aRotina := aClone(aSvRot)
EndIf

If nOpca == 1 .and. Len(aSXBCols)>0
	If !lPesqComp
		nCpoRet := GdFieldPos(cCpoRet, aSXBHeader)
		VAR_IXB  := aSXBCols[oGetDados:nAt,nCpoRet]
		
		If !Empty(cCpo2)
			Var_IXB := {}
			aadd(VAR_IXB,aSXBCols[oGetDados:nAt,nCpoRet])
			nCpoRet := GdFieldPos(cCpo2, aSXBHeader)
			cDescr := aSXBCols[oGetDados:nAt,nCpoRet]
			aadd(VAR_IXB,cDescr)
		EndIf
		If Funname() == 'GPEA320' .OR. Funname() == 'GPEM671'
			&(ReadVar()) := VAR_IXB
		EndIf
		
		If FunName() == "CGPER04"
			MV_PAR31 := aSXBCols[oGetDados:nAt, nCpoRet + 1 ]
			MV_PAR32 := aSXBCols[oGetDados:nAt, nCpoRet + 3 ]
		EndIf
	Else         
		VAR_IXB := ""	
		While lPesqComp
			cCpoAux := Substr(cCpoRet, 1, nPos - 1)
			cCpoRet := Substr(cCpoRet, nPos +1)    

			nCpoRet := GdFieldPos(cCpoAux, aSXBHeader)
			VAR_IXB += aSXBCols[oGetDados:nAt,nCpoRet]

			nPos := At("+", cCpoRet )
			lPesqComp := If (nPos > 0, .T., .F.)
			
			If nPos == 0
				nCpoRet := GdFieldPos(cCpoRet, aSXBHeader)
				VAR_IXB += aSXBCols[oGetDados:nAt,nCpoRet]
			EndIf
		EndDo
		
		If Funname() == 'GPEA320' .OR. Funname() == 'GPEM671'
			&(ReadVar()) := VAR_IXB
		EndIf
		
		If !Empty(cCpo2)
			cDescr := VAR_IXB
			Var_IXB := {}
			aadd(VAR_IXB,cDescr)
			nCpoRet := GdFieldPos(cCpo2, aSXBHeader)
			cDescr := aSXBCols[oGetDados:nAt,nCpoRet]
			aadd(VAR_IXB,cDescr)
		EndIf
	EndIf
Else
	If !Empty(cCpo2)
		Var_IXB := {}
		aadd(VAR_IXB,cSvField)
		aadd(VAR_IXB,"")
	Else
		VAR_IXB := cSvField
	EndIf
	RestArea(aArea)
	Return .T.
EndIf

RestArea( aArea )

Return(nOpca == 1)

/*==================================================================================================
	Ponto de Entrada PE_GPCHKLIQ desativado e ativado essa funcao para buscar o liquido do 14o
	para RJ, para SP nao e gerado CNAB.
@author     A.Shibao
@since      17/10/18
@param
@version    P12
@return
@project
@client    Ciee
@variaveis nLiqAux  
//================================================================================================== */
User Function fSearch14()

Local aArea   := GetArea()  
Local cVrbLiq := "" 
Local cxFound := ""
Local nLiqAux := 0
Local cxMens  := "Nao foi encontrado o vinculo (RV_XCOD14) da verba de liquido de 14o salario na verba de liquido de 13o salario. Nao sera gerado valor para o funcionario. "
//Retornar o valor liquido do 14o salario utilizado nos roteiros customizado 141 e 142.
If ("141" $ mv_par01 .or. "141" $ mv_par02 .or. "141" $ mv_par03) .And. ( len(alltrim(mv_par01)) == 3 .or. len(alltrim(mv_par02)) == 3 .or. len(alltrim(mv_par03)) == 3)
	//Liquido de 13 salario para buscar a correspondente do 14o salario 1a PARCELA
	cxFound :=Posicione("SRV",2,xFilial("SRV")+"0022","RV_COD")
	If !Empty(cxFound)
	    cVrbLiq:= SRV->RV_XCOD14                            
		nLiqAux:= u_FLiqui14(cVrbLiq,"141")
	Else
		aAdd( aLog, { OemToAnsi(cxMens) } ) 
	    //Alert(" Nao foi encontrado o vinculo (RV_XCOD14) da verba de liquido de 14o salario na verba de liquido de 13o salario. Nao sera gerado valor para o funcionario. ")
	Endif
	
Elseif ("142" $ mv_par01 .or. "142" $ mv_par02 .or. "142" $ mv_par03) .And. ( len(alltrim(mv_par01)) == 3 .or. len(alltrim(mv_par02)) == 3 .or. len(alltrim(mv_par03)) == 3)
	//Liquido de 13 salario para buscar a correspondente do 14o salario 2a PARCELA
	cxFound:= Posicione("SRV",2,xFilial("SRV")+"0024","RV_COD")
	If !Empty(cxFound)
	    cVrbLiq:= SRV->RV_XCOD14                             
		nLiqAux:= u_FLiqui14(cVrbLiq,"142")
	Else
		aAdd( aLog, { OemToAnsi(cxMens) } ) 	
	    //Alert(" Nao foi encontrado o vinculo (RV_XCOD14) da verba de liquido de 14o salario na verba de liquido de 13o salario. Nao sera gerado valor para o funcionario. ")
	Endif
	
Endif
	
RestArea(aArea)   

Return(nLiqAux)


/*============================================================================================================
 Funcao para buscar o liquido do 14 salario para 1a e 2a parcela podendo ser mes aberto ou fechado.
@author     A.Shibao
@since      17/10/18
@param
@version    P12
@return
@project
@client    Ciee
@campos
//============================================================================================================*/ 
User Function FLiqui14(cVrbLiq,cxRot)

//Local aArea   	:= GetArea() 
Local nxLiq   	:= 0
Local cQuery  	:= ""
Local cQAlias 	:= GetNextAlias()
Local dDataRef	:= If (Empty(mv_par25), dDataBase,mv_par25)


cQuery := "SELECT RC_VALOR AS LIQUIDO FROM "+RetSqlName('SRC')+" SRC "
cQuery += "WHERE SRC.D_E_L_E_T_ = '' "
cQuery += "AND RC_PD = '"+cVrbLiq+"' "
cQuery += "AND RC_PERIODO = '"+ AnoMes(dDataRef)+"' "
cQuery += "AND RC_DATA    >= '"+ Dtos(mv_par21)  +"' AND RC_DATA <= '" + Dtos(mv_par22) + "' "
cQuery += "AND RC_FILIAL  = '"+ SRA->RA_FILIAL + "' "
cQuery += "AND RC_MAT     = '"+ SRA->RA_MAT    + "' "
cQuery += "AND RC_ROTEIR  = '"+ cxRot     + "' "
cQuery += "UNION "
cQuery += "SELECT RD_VALOR AS LIQUIDO FROM "+RetSqlName('SRD')+" SRD "
cQuery += "WHERE SRD.D_E_L_E_T_ = '' "
cQuery += "AND RD_PD = '"+cVrbLiq+"' "
cQuery += "AND RD_PERIODO = '"+ AnoMes(dDataRef)+ "' "
cQuery += "AND RD_DATPGT  >= '"+ Dtos(mv_par21)  + "' AND RD_DATPGT <= '" + Dtos(mv_par22) + "' "
cQuery += "AND RD_FILIAL  = '"+ SRA->RA_FILIAL + "' "
cQuery += "AND RD_MAT     = '"+ SRA->RA_MAT    + "' "
cQuery += "AND RD_ROTEIR  = '"+ cxRot     + "' " 

dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cQAlias , .F., .T. )

nxLiq := (cQAlias)->LIQUIDO

(cQAlias)->(DbCloseArea()) 

Return(nxLiq)

/*============================================================================================================
  PONTO DE ENTRADA PARA ALTERAR O NOME DA VARIAVEL CARQSAIDA CNAB MODELOS 1 E 2.  
  OBS: Esse PE ï¿½ chamado tb na rotina CGPER01.prw responsavel para gerar os liquidos de outros roteiros e caso
       seja alterado a ordem do parametro do banco deve-se ajustar esse PE, pois hoje estao na mesma ordem.
@author     A.Shibao
@since      28/11/18
@param
@version    P12
@return
@project
@client    Ciee
@campos  
@variaveis cShSaida e cArqent - privates
//============================================================================================================*/
Static Function XGP410AR(lAuto)             // funcao para buscar o local de gravacao do cnab e nomear o arquivo conforme processo.

Local cXvalidacao:= "  "

_cFil		:= XFILIAL("SEE") //mv_par05
_cEmp       := cEmpAnt 
 mvRet		:= Alltrim(ReadVar())
 cTime 		:= TIME()
 cSeq       := U_CNABSeq() 
 cShSaida   := ""
 nSFilial   := Val(str(GetSx3Cache("RA_FILIAL","X3_TAMANHO")))
 cSBank     := mv_par30 //Iif(Funname() == "GPEM080",mv_par30,mv_par30)     
 cSAgen     := mv_par31 //Iif(Funname() == "GPEM080",mv_par30,mv_par30)
 cSCont     := mv_par32 //Iif(Funname() == "GPEM080",mv_par30,mv_par30)
 cxNomeArq  := fxNomeArq(cSBank)   
 xaTabS052  := {}
 xcCodBanco := AllTrim(mv_par30)  
 xcCodAgen  := AllTrim(mv_par31)     
 
 
fCarrTab( @xaTabS052, "S052", Nil)
 
If Len( xaTabS052 ) == 0 .Or. ( nPos := aScan(xaTabS052,{|x| AllTrim(x[6]) == xcCodBanco .and. AllTrim(x[7]) == xcCodAgen .and. (Empty(x[2]) .or. x[2] == xFilial("SEE"))}) ) == 0
	if lAuto
		U_CJBK03LOG(2,"Banco: " + Alltrim(xcCodBanco) + " e Filial para processamento do CNAB não cadastrados na tabela S052! Favor verificar!","1")
	else
		If !_lJob
   			Aviso("ATENCAO","Banco: " + Alltrim(xcCodBanco) + " e Filial para processamento do CNAB n?o cadastrados na tabela S052! Favor verificar!",{"Sair"}) 
		ENDIF
	endif	
	if lPgtoBA
		If !_lJob
			Aviso("ATENCAO","Banco: " + Alltrim(xcCodBanco) + " e Filial para processamento do CNAB n?o cadastrados na tabela S052! Favor verificar!",{"Sair"}) 
		ENDIF
	Endif
	   
	Return .F.
Elseif nPos > 0 .AND. !IsInCallStack("U_CFINA92")
	cArqSaida:= xaTabS052[nPos][14]
EndIf 
 
dbSelectArea("SEE")   // Tabela de Bancos 
dbSetOrder(1)

//If SEE->(!DbSeek(_cFil+cSBank+cSAgen)) .And. SEE->(!DbSeek(_cFil+cSBank+cSAgen+cSCont)) 
if !(SEE->(DbSeek(_cFil+cSBank+cSAgen+PadR(AllTrim(cSCont),FwTamSX3("EE_CONTA")[1]," ")))) 
	if lAuto
		U_CJBK03LOG(2,"Nao foi encontrado nenhum registro de configuracao na tabela SEE","1")
	else
		If !_lJob
			Alert("Banco: " + Alltrim(xcCodBanco) + "- Nao foi encontrado nenhum registro de configuracao na tabela SEE", "Avisar a Equipe de TI")
		ENDIF
	endif	
	if lPgtoBA
		If !_lJob
			Alert("Banco: " + Alltrim(xcCodBanco) + "- Nao foi encontrado nenhum registro de configuracao na tabela SEE", "Avisar a Equipe de TI")
		ENDIF
	Endif
Else
	//Trata Nome do Arquivo
	cXvalidacao:= "S1_"
	
	If mv_par35 == 2	//Validacao	de conta R$0.01
		cXvalidacao:= "SV_"
		cArqSaida := STRTRAN(TRIM(cArqSaida),"APROVACAO","REMESSA")
	Endif

	cShSaida :=	ALLTRIM(cArqSaida) + cXvalidacao + Substr(dtoS(MV_PAR20),7,2) + Substr(dtoS(MV_PAR20),5,2) + Substr(dtoS(MV_PAR20),3,2) + "_" + Right(cSeq,3)+ ".REM"
Endif

Return (cShSaida)           

*----------------------------------*
User Function fInfCnab(nRet)          // funcao para buscar o conteudo da tabela S052
/*
Abaixo apenas um exemplo de como colocar no arquivo de configuracao do banco
21H COD. CONV. BCO 0330520 U_fInfCnab(5)                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
21H AG. MANT CC    0530570 U_fInfCnab(7)                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
21H DIG. AG        0580580 U_fInfCnab(8)                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
21H CONTA CORRENTE 0590700 U_fInfCnab(9)                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
21H DIG. VERF.CC   0710710 U_fInfCnab(10) 
*/
*----------------------------------*

Private xaTabS052 := {}
Private xcCodBanco := mv_par30  
Private xcCodAgen  := mv_par31

fCarrTab( @xaTabS052, "S052", Nil)

If Len( xaTabS052 ) == 0 .Or. ( nPos := aScan(xaTabS052,{|x| x[6] == xcCodBanco .and. x[7] == xcCodAgen .and. (Empty(x[2]) .or. x[2] == xFilial("SRA"))}) ) == 0
	if lPgtoBA
		U_CJBK03LOG(2,"Banco e Filial para processamento do CNAB nï¿½o cadastrados na tabela S052! Favor verificar!","1")
	else
		If !_lJob	
   			Aviso("ATENCAO","Banco e Filial para processamento do CNAB nï¿½o cadastrados na tabela S052! Favor verificar!",{"Sair"}) 
		ENDIF
	endif	   
	Return .F.
EndIf

Private xcCodFilial := xaTabS052[nPos,2]  //2
Private xcCodConve  := xaTabS052[nPos,5]  //5
Private xcCodAgenc  := xaTabS052[nPos,7]  //7
Private xcDigAgenc  := xaTabS052[nPos,8]  //8
Private xcCodConta  := xaTabS052[nPos,9]  //9
Private xcDigConta  := xaTabS052[nPos,10] //10
Private xcSequenci  := xaTabS052[nPos,11] //10

Return xaTabS052[nPos,nRet]
                                                
*----------------------------------*
Static Function fxNomeArq(cBanco)
*----------------------------------*

Local cArq_:= ""

If funname() == "GPEM080"
	If !_lJob
		Alert("Voce esta usando a rotina padrao de geracao de CNAB e o nome do arquivo a ser gerado nao sera no padrao CIEE.", "Ok !")  
	ENDIF
	//Ex: ROTEIRO(MV_PAR01) + DT REFERENCIA(MV_PAR25) + SEQUENCIA + Time + .txt
	//Ex: FOL2016010100001125151.TXT                           
	cArq_ := alltrim(MV_PAR01) + alltrim(dtoS(mv_par25)) + cSeq + alltrim(StrTran(cTime,":",""))
Else	
	// BB
	If cBanco == "001"  

		// APRENDIZ	
		If Substr(cFilAnt,7,2) == "02"

			If mv_par35 == 2 			    			//Validacao	de conta de Aprendiz
				cArq_:= "BB_AV"                                                                                                                   		                               					
			Elseif 	aroteiros[1,1] == "FER" 			//Pagamento ferias Aprendiz
				cArq_:= "BB_A3"
			Elseif 	aroteiros[1,1] == "RES" 			//Pagamento RESCISAO Aprendiz
				cArq_:= "BB_A4"
			ElseIf aroteiros[1,1] $ "VTR/VAL/VRF/BEN/ATM/DUC/EST/FRE/VMS" 		//Pagamento beneficios Aprendiz
				cArq_:= "BB_A1"
			Else							  	        //Pagamento FOLHA  Aprendiz
				cArq_:= "BB_A2"
			EndIf

		// CLT	
		Else	

		    // ESTAGIARIOS
			If mv_par35 == 2  .And. ("E" $ MV_PAR23 .or. "G" $ MV_PAR23 )                	//Validacao	de conta de estagiario
				cArq_:= "BB_SV"                                                                                                                   
			ElseIf ("E" $ MV_PAR23 .or. "G" $ MV_PAR23 ) .And. aroteiros[1,1] == "FOL"   	//Pagamento de salario estagiario
				cArq_:= "BB_S1"                                                                                                                   		                               

			ElseIf mv_par35 == 2  				    	//Validacao de conta de CLT
				cArq_:= "BB_PV"                                                                                                                  		                               					
			Elseif 	aroteiros[1,1] == "FER" 			//Pagamento ferias CLT
				cArq_:= "BB_P3"
			Elseif 	aroteiros[1,1] == "RES" 			//Pagamento RESCISAO CLT
				cArq_:= "BB_P4"
			ElseIf aroteiros[1,1] $ "VTR/VAL/VRF/BEN/ATM/DUC/EST/FRE/VMS" 		//Pagamento beneficios CLT
				cArq_:= "BB_P1"
			Else 	  	        						//Pagamento FOLHA  CLT
				cArq_:= "BB_P2" 
			EndIf

		Endif 
		
	// Itau
	ElseIf cBanco == "341" 
		
		// APRENDIZ	
		If Substr(cFilAnt,7,2) == "02"

			If mv_par35 == 2 			    			//Validacao	de conta de Aprendiz
				cArq_:= "IT_AV"                                                                                                                   		                               					
			Elseif 	aroteiros[1,1] == "FER" 			//Pagamento ferias Aprendiz
				cArq_:= "IT_A3"
			Elseif 	aroteiros[1,1] == "RES" 			//Pagamento RESCISAO Aprendiz
				cArq_:= "IT_A4"
			ElseIf aroteiros[1,1] $ "VTR/VAL/VRF/BEN/ATM/DUC/EST/FRE/VMS" 		//Pagamento beneficios Aprendiz
				cArq_:= "IT_A1"
			Else							  	        //Pagamento FOLHA  Aprendiz
				cArq_:= "IT_A2"
			EndIf

		// CLT	
		Else	

		    // ESTAGIARIOS
			If mv_par35 == 2  .And. ("E" $ MV_PAR23 .or. "G" $ MV_PAR23 )                	//Validacao	de conta de estagiario
				cArq_:= "IT_SV"                                                                                                                   
			ElseIf ("E" $ MV_PAR23 .or. "G" $ MV_PAR23 ) .And. aroteiros[1,1] == "FOL"   	//Pagamento de salario estagiario
				cArq_:= "IT_S1"                                                                                                                   		                               

			ElseIf mv_par35 == 2  				    	//Validacao de conta de CLT
				cArq_:= "IT_PV"                                                                                                                  		                               					
			Elseif 	aroteiros[1,1] == "FER" 			//Pagamento ferias CLT
				cArq_:= "IT_P3"
			Elseif 	aroteiros[1,1] == "RES" 			//Pagamento RESCISAO CLT
				cArq_:= "IT_P4"
			ElseIf aroteiros[1,1] $ "VTR/VAL/VRF/BEN/ATM/DUC/EST/FRE/VMS" 		//Pagamento beneficios CLT
				cArq_:= "IT_P1"
			Else 	  	        						//Pagamento FOLHA  CLT
				cArq_:= "IT_P2" 
			EndIf

		Endif 

	// Santander
	ElseIf cBanco == "033"
	
		// APRENDIZ	
		If Substr(cFilAnt,7,2) == "02"

			If mv_par35 == 2 			    			//Validacao	de conta de Aprendiz
				cArq_:= "ST_AV"                                                                                                                   		                               					
			Elseif 	aroteiros[1,1] == "FER" 			//Pagamento ferias Aprendiz
				cArq_:= "ST_A3"
			Elseif 	aroteiros[1,1] == "RES" 			//Pagamento RESCISAO Aprendiz
				cArq_:= "ST_A4"
			ElseIf aroteiros[1,1] $ "VTR/VAL/VRF/BEN/ATM/DUC/EST/FRE/VMS" 		//Pagamento beneficios Aprendiz
				cArq_:= "ST_A1"
			Else							  	        //Pagamento FOLHA  Aprendiz
				cArq_:= "ST_A2"
			EndIf

		// CLT	
		Else	

		    // ESTAGIARIOS
			If mv_par35 == 2  .And. ("E" $ MV_PAR23 .or. "G" $ MV_PAR23 )                	//Validacao	de conta de estagiario
				cArq_:= "ST_SV"                                                                                                                   
			ElseIf ("E" $ MV_PAR23 .or. "G" $ MV_PAR23 ) .And. aroteiros[1,1] == "FOL"   	//Pagamento de salario estagiario
				cArq_:= "ST_S1"                                                                                                                   		                               

			ElseIf mv_par35 == 2  				    	//Validacao de conta de CLT
				cArq_:= "ST_PV"                                                                                                                  		                               					
			Elseif 	aroteiros[1,1] == "FER" 			//Pagamento ferias CLT
				cArq_:= "ST_P3"
			Elseif 	aroteiros[1,1] == "RES" 			//Pagamento RESCISAO CLT
				cArq_:= "ST_P4"
			ElseIf aroteiros[1,1] $ "VTR/VAL/VRF/BEN/ATM/DUC/EST/FRE/VMS" 		//Pagamento beneficios CLT
				cArq_:= "ST_P1"
			Else 	  	        						//Pagamento FOLHA  CLT
				cArq_:= "ST_P2" 
			EndIf

		Endif 
		
	// Bradesco
	ElseIf cBanco == "237"
	
		// APRENDIZ	
		If Substr(cFilAnt,7,2) == "02"
			
			If mv_par34 == 1 .And. ( Substr(mv_par08,1,3) == "104" .And. Substr(mv_par09,1,3) == "104" ) .And. mv_par30 == "237"
				cXLetr:= "CE"
			ElseIf mv_par34 == 1 .And. ( Substr(mv_par08,1,3) == "003" .And. Substr(mv_par09,1,3) == "003" ) .And. mv_par30 == "237"
				cXLetr:= "AM"
			else
				cXLetr:= "BR"
			Endif

			If mv_par35 == 2 			    			//Validacao	de conta de Aprendiz
				cArq_:= cXLetr+"_AV"                                                                                                                   		                               					
			Elseif 	aroteiros[1,1] == "FER" 			//Pagamento ferias Aprendiz
				cArq_:= cXLetr+"_A3"
			Elseif 	aroteiros[1,1] == "RES" 			//Pagamento RESCISAO Aprendiz
				cArq_:= cXLetr+"_A4"
			ElseIf aroteiros[1,1] $ "VTR/VAL/VRF/BEN/ATM/DUC/EST/FRE/VMS" 		//Pagamento beneficios Aprendiz
				cArq_:= cXLetr+"_A1"
			Else							  	        //Pagamento FOLHA  Aprendiz
				cArq_:= cXLetr+"_A2"
			EndIf

		// CLT	
		Else	

		    // ESTAGIARIOS
			If mv_par35 == 2  .And. ("E" $ MV_PAR23 .or. "G" $ MV_PAR23 )                	//Validacao	de conta de estagiario
				cArq_:= "BR_SV"                                                                                                                   
			ElseIf ("E" $ MV_PAR23 .or. "G" $ MV_PAR23 ) .And. aroteiros[1,1] == "FOL"   	//Pagamento de salario estagiario
				cArq_:= "BR_S1"                                                                                                                   		                               

			ElseIf mv_par35 == 2  				    	//Validacao de conta de CLT
				cArq_:= "BR_PV"                                                                                                                  		                               					
			Elseif 	aroteiros[1,1] == "FER" 			//Pagamento ferias CLT
				cArq_:= "BR_P3"
			Elseif 	aroteiros[1,1] == "RES" 			//Pagamento RESCISAO CLT
				cArq_:= "BR_P4"
			ElseIf aroteiros[1,1] $ "VTR/VAL/VRF/BEN/ATM/DUC/EST/FRE/VMS" 		//Pagamento beneficios CLT
				cArq_:= "BR_P1"
			Else 	  	        						//Pagamento FOLHA  CLT
				cArq_:= "BR_P2" 
			EndIf

		Endif 
		
		
	/* Bradesco DOC Amazonia	
	ElseIf cBanco == "237" .And. Substr(cFilAnt,7,2) == "02"  .And. (Substr(mv_par08,1,3) == "003" .And. Substr(mv_par09,1,3) == "003")
	
		If mv_par35 == 2 								//Validaï¿½ï¿½o GA_BRAPVL010701.REM                             
			cArq_:= "GA_BRAPVL"
		ElseIf aroteiros[1,1] $ "VTR"			 	    //VT    	GA_BAAPVT010701.REM
			cArq_:= "GA_BAAPVT"
		ElseIf aroteiros[1,1] $ "VRF"			 	    //VR    	GA_BAAPTA010701.REM
			cArq_:= "GA_BAAPTA"
		Elseif 	aroteiros[1,1] == "FER" 				//Fï¿½RIAS	GA_BAAPFE010701.REM
			cArq_:= "GA_BAAPFE"
		Elseif 	aroteiros[1,1] == "RES" 				//RESCISï¿½O	GA_BAAPRE010701.REM
			cArq_:= "GA_BAAPRE"
		Else 									 	    //SALARIO	GA_BAAPFP010701.REM 
			cArq_:= "GA_BAAPFP"
		Endif                        
		
		cArq_+=	"_"+Substr(dtoS(MV_PAR20),7,2) + Substr(dtoS(MV_PAR20),5,2) + Substr(dtoS(MV_PAR20),3,2) + "_" + Right(cSeq,6)
		
	 Bradesco DOC CEF	
	ElseIf cBanco == "237" .And. Substr(cFilAnt,7,2) == "02" .And. (Substr(mv_par08,1,3) == "104" .And. Substr(mv_par09,1,3) == "104")
	
		If mv_par35 == 2 								//Validaï¿½ï¿½o GA_BRAPVL010701.REM                             
			cArq_:= "GA_BRAPVL"
		ElseIf aroteiros[1,1] $ "VTR"			 	    //VT    	GA_CEFAPVT010701.REM
			cArq_:= "GA_CEFAPVT"
		ElseIf aroteiros[1,1] $ "VRF"			 	    //VR    	GA_CEFAPTA010701.REM
			cArq_:= "GA_CEFAPTA"
		Elseif 	aroteiros[1,1] == "FER" 				//Fï¿½RIAS	GA_CEFAPFE010701.REM
			cArq_:= "GA_CEFAPFE"
		Elseif 	aroteiros[1,1] == "RES" 				//RESCISï¿½O	GA_CEFAPRE010701.REM
			cArq_:= "GA_CEFAPRE"
		Else 									 	    //SALARIO	GA_CEFAPFP010701.REM 
			cArq_:= "GA_CEFAPFP"
		Endif  
		
		cArq_+=	"_"+Substr(dtoS(MV_PAR20),7,2) + Substr(dtoS(MV_PAR20),5,2) + Substr(dtoS(MV_PAR20),3,2) + "_" + Right(cSeq,6)
	 */

	Endif 

	cArq_+=	"_"+Substr(dtoS(MV_PAR20),7,2) + Substr(dtoS(MV_PAR20),5,2) + Substr(dtoS(MV_PAR20),3,2) + "_" + Right(cSeq,3)
	
Endif
	
Return(cArq_)

/*/{Protheus.doc} ReDadBco
Consulta padrão utilizado no parâmetro do pergunte XGPEM080R1
@author Danilo José Grodzicki
@since 16/03/2020
@version undefined
@type user function
/*/
User Function ReDadBco(cTipo)

Local  cRet := space(18)

DbSelectArea("RCC")
RCC->(DbSetOrder(1))

if cTipo == "T"
	GP310SXB("S052","BRA_S05201")  // Código do convênio
	Return(.T.)
endif

if cTipo == "B"
	if RCC->(DbSeek(xFilial("RCC")+"S052"))
		while RCC->RCC_FILIAL+RCC->RCC_CODIGO == xFilial("RCC")+"S052" .and. RCC->(!Eof())
			if Left(RCC->RCC_CONTEU,20) == VAR_IXB
				cRet := Subs(RCC->RCC_CONTEU,21,3)   // Banco
				exit
			endif
			RCC->(Dbskip())
		enddo
	endif
endif

if cTipo == "A"
	if RCC->(DbSeek(xFilial("RCC")+"S052"))
		while RCC->RCC_FILIAL+RCC->RCC_CODIGO == xFilial("RCC")+"S052" .and. RCC->(!Eof())
			if Left(RCC->RCC_CONTEU,20) == VAR_IXB
				cRet := Subs(RCC->RCC_CONTEU,24,5)   // Agência
				exit
			endif
			RCC->(Dbskip())
		enddo
	endif
endif

if cTipo == "C"
	if RCC->(DbSeek(xFilial("RCC")+"S052"))
		while RCC->RCC_FILIAL+RCC->RCC_CODIGO == xFilial("RCC")+"S052" .and. RCC->(!Eof())
			if Left(RCC->RCC_CONTEU,20) == VAR_IXB
				cRet := Subs(RCC->RCC_CONTEU,30,12)  // Conta corrente
				exit
			endif
			RCC->(Dbskip())
		enddo
	endif
endif

if cTipo == "Q"
	if RCC->(DbSeek(xFilial("RCC")+"S052"))
		while RCC->RCC_FILIAL+RCC->RCC_CODIGO == xFilial("RCC")+"S052" .and. RCC->(!Eof())
			if Left(RCC->RCC_CONTEU,20) == VAR_IXB
				cRet := Subs(RCC->RCC_CONTEU,50,12)  // Arquivo de configuração
				exit
			endif
			RCC->(Dbskip())
		enddo
	endif
endif

if cTipo == "S"
	if RCC->(DbSeek(xFilial("RCC")+"S052"))
		while RCC->RCC_FILIAL+RCC->RCC_CODIGO == xFilial("RCC")+"S052" .and. RCC->(!Eof())
			if Left(RCC->RCC_CONTEU,20) == VAR_IXB
				cRet := Subs(RCC->RCC_CONTEU,62,100)  // path de saida
				exit
			endif
			RCC->(Dbskip())
		enddo
	endif
endif

Return(cRet)

static function fGeraTit(cConta, nValConta, cNumTit)
	local aArray			:= {}
	local aFornece
	Private lMsHelpAuto    	:= .T.
	Private lMsErroAuto    	:= .F.
	Private lAutoErrNoFile 	:= .T.

	if cConta == "237"
		aFornece := strTokArr(SuperGetMv("CI_FORNBC",, "000154-01"), "-")
	elseif cConta == "001"
		aFornece := strTokArr(SuperGetMv("CI_FORNBC",, "001045-01"), "-")
	elseif cConta == "033"
		aFornece := strTokArr(SuperGetMv("CI_FORNBC",, "024914-01"), "-")
	elseif cConta == "341"
		aFornece := strTokArr(SuperGetMv("CI_FORNBC",, "010132-01"), "-")
	elseif cConta == "104"
		aFornece := strTokArr(SuperGetMv("CI_FORNBC",, "000482-01"), "-")
	endif

	aArray := { { "E2_NUM"      , getsxenum("SE2", "E2_NUM")               									, NIL },;
				{ "E2_TIPO"     , "PBA"               														, NIL },;
				{ "E2_PREFIXO"  , "VCE" 			  														, NIL },;
				{ "E2_FORNECE"  , aFornece[1]            													, NIL },;
				{ "E2_LOJA"     , aFornece[2]				  												, NIL },;
				{ "E2_EMISSAO"  , ddatabase       		  													, NIL },;
				{ "E2_VENCTO"   , ddatabase       		  													, NIL },;
				{ "E2_RATEIO"   , "N"                                                        				, NIL },;
				{ "E2_XHISFLG"  , ""			  															, NIL },;
				{ "E2_XREDUZ"   , "21701"             		  												, NIL },;
				{ "E2_XCONTAB"  , "201060100001 "             		  										, NIL },;
				{ "E2_ITEMD"    , ""                                                         		  		, NIL },;
				{ "E2_FILORIG"  , cFilAnt              		  												, NIL },;
				{ "E2_XFLUIG"   , ""              		  													, NIL },;
				{ "E2_XIDFLG"   , ""              		  													, NIL },;
				{ "E2_XFLGUSR"  , ""             		  													, NIL },;
				{ "E2_XFLGCRS"  , ""             		  													, NIL },;
				{ "E2_VALOR"    , nValConta                                                         		, NIL } }

	MsExecAuto({|x,y,z,a,b,c| FINA050(x,y,z,a,b,c)},aArray,,3,,,.F.)

	If lMsErroAuto

		If (__lSX8)
			RollBackSX8()
		EndIf

		DisarmTransaction()

	Else

		If (__lSX8)
			ConfirmSX8()
		EndIf		

		cNumTit := SE2->E2_NUM

	endif
return

/*/{Protheus.doc} AtuNumdoc
Rotina de atualização do numero do documento do CNAB
@type  User Function
@author Carlos Henrique
@since 15/05/2020
@version version
/*/
Static Function AtuNumdoc(aValBenef)
Local aAreaSRA:= SRA->(Getarea())
Local aAreaSRQ:= SRQ->(Getarea())
Local cNumDoc := ""
Local nCnta   := 0
local nValConta	:= 0
local cNumTit	:= ""

If mv_par35 == 2 .and. len(aValBenef) > 0
	for nCnta:= 1 to len(aValBenef)
		if aValBenef[nCnta][8] == "SRA"
			nValConta++
		endif
	next

	if nValConta > 0

		nValConta := nValConta / 100

		fGeraTit(aValBenef[1, 10], nValConta, @cNumTit)
	endif
endif

for nCnta:= 1 to len(aValBenef)
	IF aValBenef[nCnta][8] == "SRA"

		SRA->(DBGOTO(aValBenef[nCnta][7]))
		
		If mv_par35 == 2

			RECLOCK("SRA",.F.)		
				SRA->RA_XVALIBC:= '2'	
				SRA->RA_XTITVLD:= cNumTit
			MSUNLOCK()
		
		Else
        	
			cNumDoc:= GetSX8Num("SRD","RD_XNUMDOC")
	    	ConfirmSx8()

			RECLOCK("SRA",.F.)				
				SRA->RA_XNUDOC := cNumDoc				
			MSUNLOCK()

			IF TCSQLEXEC("UPDATE "+RETSQLNAME("SRD")+ " SET RD_XNUMDOC='"+cNumDoc+"'"+;
						" WHERE RD_FILIAL='"+SRA->RA_FILIAL+"'"+;
						" AND  RD_MAT='"+SRA->RA_MAT+"'"+;
						" AND  RD_DATPGT='"+ DTOS(dDataDe)  +"'"+;  //  " AND  RD_DTREF='"+ DTOS(dDataDe)  +"'"+;  Alterada porque a variável dDataDe é a data de pagamento
						" AND  RD_PD='J99'"+;
						" AND  RD_ROTEIR='FOL'") < 0
				ALERT(TCSQLError())
			ENDIF

		Endif

	ENDIF
next

Restarea(aAreaSRQ)
Restarea(aAreaSRA)
Return



/*
Funcao  BuscaLiq - COPIA DA FUNÇÃO PADRAO UTILIZADA APENAS PARA REALIZAR DEBUG - 
Descricao ³ Busca os valores de liquido e beneficios                       
aValBenef   - 1-Nome/2-Banco/3-Conta/4-Verba/5-Valor Benef 
*/
USER Function BuscaLiq(nValLiq,aValBenef,cVerba)
Local aCodBenef   	:= {}
Local aCodBenefAux  := {}
Local aChaveBusca 	:= {}
//Local aAreaSra    	:= SRA->( GetArea() )
Local aPensPd		:= {} //{ cRoteiro, PERIODO, SEMANA, ORIGEM, DATAPAG, DTREF, PD }
Local cVerbaBusca 
Local cRoteiro
Local lResArea 		:= .F.
Local nCntP,nCntP2,nPosBenef
Local nRoteiro   
//Local nPosFol
Local nValVrb   := 0
Local nValBenef := 0
Local lRatItm   := SuperGetMv("MV_RATITM",, .F.)
Local nx		:= 0
Local nY		:= 0
lOCAL lGPCHKLIQ:= .F.

Private nLiqAux 	:= 0 // Variavel para acumular outros valores de liquidos para utilizacao no Ponto de Entrada.
Private	cTipoRot	:= ""	

If Empty(cAcessaSRC)
	cAcessaSRC	:= &( " { || " + ChkRH( "GPER020" , "SRC" , "2" ) + " } " )
EndIf
If Empty(cAcessaSRD)
	cAcessaSRD	:= &( " { || " + ChkRH( "GPER020" , "SRD" , "2" ) + " } " )
EndIf

If Empty(cAcessaSRR)
	cAcessaSRR	:= &( " { || " + ChkRH( "GPER020" , "SRR" , "2" ) + " } " )
EndIf

If Empty(cAcessaSRG)
	cAcessaSRG	:= &( " { || " + ChkRH( "GPER020" , "SRG" , "2" ) + " } " )
EndIf

If Empty(cAcessaSRH)
	cAcessaSRH	:= &( " { || " + ChkRH( "GPER020" , "SRH" , "2" ) + " } " )  
EndIf

If Empty(lGPCHKLIQ)
	lGPCHKLIQ := ExistBlock("GPCHKLIQ")
EndIf

	If Type("lImprFunci") = "U"
		Private lImprFunci := .T.
	EndIf 
	
	If Type("lImprBenef") = "U"
		Private lImprBenef := .T.
	EndIf
	
	Default cVerba := ""

	// Ponto de Entrada para alterar as variaveis de liquido. Ex. lAdianta    
	// Impressao/Geracao de liquidos : A partir da 7.10, a rotina passou a    
	// listar  valor liquido da rescisão contratual dos funcionários demitidos
	// de acordo com  as faixas de datas de pagamento selecionadas.           
	// No entanto, algumas empresas lancam o Id47 (Liq. a receber)no SRC e    
	// neste caso, nao deveria pegar o Liq.Rescisao, duplicando o Vlr. Liq.ge-
	// rado no Relat./Geracao Liq.                                            
	If lGPCHKLIQ
		ExecBlock("GPCHKLIQ",.F.,.F.)
		nValLiq += nLiqAux
	EndIf

	For nRoteiro := 1 to Len(aRoteiros)
	
		cRoteiro 	:= aRoteiros[nRoteiro, 1]
		cTipoRot 	:= aRoteiros[nRoteiro, 2]
		cVerbaBusca := If(Empty(cVerba),aRoteiros[nRoteiro, 3],cVerba)	
	
		// Busca liquido e beneficios das Ferias			   			 
		If cTipoRot == "3"		
			dbSelectArea( "SRH" )
			SRH->(dbSetOrder( 3 )) 
			If lImprFunci // Busca Liquido
				If dbSeek( SRA->RA_FILIAL + SRA->RA_MAT + cRoteiro ) .And. Eval(cAcessaSRH)
					While !Eof() .And. Alltrim(SRA->RA_FILIAL + SRA->RA_MAT + cRoteiro) = Alltrim(SRH->RH_FILIAL + SRH->RH_MAT + SRH->RH_ROTEIR)
						If (SRH->RH_DTRECIB >= dDataDe .And. SRH->RH_DTRECIB <= dDataAte ) 
							dDtBusFer := SRH->RH_DATAINI
							dbSelectArea( "SRR" )
							dbSetOrder( 3 )
							If dbSeek( SRA->RA_FILIAL + SRA->RA_MAT + "F" + DTOS(dDtBusFer) + cVerbaBusca + cRoteiro )
								nValLiq += SRR->RR_VALOR
								If !Empty(cVerba)
									nValVrb += SRR->RR_VALOR
								EndIf
								
								If ( FunName() == "GPEM650" ) .AND. lRatItm //se geracao de titulo e rateio por Item
									fRatPensao(RetSqlName("SRR"), "RR_", SRR->RR_PD, dDataDe, dDataAte, SRA->RA_FILIAL, SRA->RA_MAT)
								EndIf
							EndIf
						EndIf
						dbSelectArea("SRH")
						dbSkip()
					Enddo
				EndIf
			EndIf
			
			If lImprBenef // Busca beneficios
				aRot:= {"131","132","FER"}
				For nx:= 1 to Len (aRot)
					cRoteiro:= aRot[nx]
					fBusCadBenef(@aCodBenefAux,cRoteiro,, .T.)
					For nY:= 1 to Len(aCodBenefAux)
						If !Empty(aCodBenefAux[nY])
							Aadd(aCodBenef,aCodBenefAux[nY])
						Endif
					Next nY
				Next 
				
				If dbSeek( SRA->RA_FILIAL + SRA->RA_MAT + cRoteiro ) .And. Eval(cAcessaSRH)
					While !Eof() .And. Alltrim(SRA->RA_FILIAL + SRA->RA_MAT + cRoteiro) = Alltrim(SRH->RH_FILIAL + SRH->RH_MAT + SRH->RH_ROTEIR)
						If (SRH->RH_DTRECIB >= dDataDe .And. SRH->RH_DTRECIB <= dDataAte )
							dDtBusFer := SRH->RH_DATAINI
							dbSelectArea( "SRR" )
							dbSetOrder( 3 )
							For nCntP := 1 To Len(aCodBenef)
								If dbSeek( SRA->RA_FILIAL + SRA->RA_MAT + "F" + DTOS(dDtBusFer) + aCodBenef[nCntP,1] + cRoteiro )
									nPosBenef := Ascan( aValBenef, { |x| x[2]+x[3] == aCodBenef[nCntP,10]+aCodBenef[nCntP,11]+aCodBenef[nCntP,12]+aCodBenef[nCntP,01] } )
									If nPosBenef == 0
										Aadd(aValBenef, {  aCodBenef[nCntP,09],  aCodBenef[nCntP,10], aCodBenef[nCntP,11], SRR->RR_PD, SRR->RR_VALOR,aCodBenef[nCntP,12],aCodBenef[nCntP,19],"SRQ", If(Len(aCodBenef[nCntP]) >= 22, aCodBenef[nCntP,22], ""),aCodBenef[nCntP,23],aCodBenef[nCntP,24] } ) 
									Else
										aValBenef[nPosBenef,5] += SRR->RR_VALOR
									EndIf
									
									If ( FunName() == "GPEM650" ) .AND. lRatItm //se geracao de titulo e rateio por Item
										fRatPensao(RetSqlName("SRR"), "RR_", SRR->RR_PD, dDataDe, dDataAte, SRA->RA_FILIAL, SRA->RA_MAT)
									EndIf
									
									If Empty(aPensPd) .Or. aScan(aPensPd, { |x| x[1] == cRoteiro .And. x[2] == SRR->RR_PERIODO .And. x[3] == SRR->RR_SEMANA .And. x[4] == SRR->RR_TIPO3 .And. x[5] == SRR->RR_DATAPAG .And. x[6] == SRR->RR_DTREF .And. x[7] == SRR->RR_PD } ) == 0
										Aadd(aPensPd, { cRoteiro, SRR->RR_PERIODO, SRR->RR_SEMANA, SRR->RR_TIPO3, SRR->RR_DATAPAG, SRR->RR_DTREF, SRR->RR_PD } )
									Endif
								EndIf
							Next nCntP
						EndIf
						dbSelectArea("SRH")
						dbSkip()
					Enddo
				EndIf
			EndIf							 
		ElseIf cTipoRot $ "4*A" // Busca liquido e beneficios da Rescisao	
			// Verifica Todos os Registros do Funcionario no "SRG"          
			dbSelectArea("SRG")                                                       
			dbSetOrder( 2 )
			If dbSeek( SRA->RA_FILIAL + SRA->RA_MAT + cRoteiro) .And. Eval(cAcessaSRG)
				aChaveBusca := {}
				While !Eof() .And. ( AllTrim(SRA->RA_FILIAL + SRA->RA_MAT + cRoteiro) ) == ( AllTrim(SRG->RG_FILIAL + SRG->RG_MAT + SRG->RG_ROTEIR) )
					If SRG->RG_DATAHOM >= dDataDe .And. SRG->RG_DATAHOM <= dDataAte
						Aadd(aChaveBusca, SRG->RG_FILIAL + SRG->RG_MAT + "R" + DTOS(SRG->RG_DTGERAR))
					EndIf
					dbSkip()
				Enddo
				
				// Verifica Qual Registro Deve Buscar no "SRR"                  
				nBusca := If( Len(aChaveBusca) == 1, 1, Len(aChaveBusca) )
				If nBusca > 0
					If lImprFunci // Busca Liquido
						dbSelectArea( "SRR" )
							
						If dbSeek( aChaveBusca[nBusca] + cVerbaBusca )
							nValLiq += SRR->RR_VALOR
						EndIf
					EndIf
					
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Busca os beneficios definidos no cadastro beneficiarios		 ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					nValBenef := 0
					If lImprBenef // Busca beneficios 
						fBusCadBenef(@aCodBenef, cRoteiro,,.T.)
						
						For nCntP := 1 To Len(aCodBenef)
							cCodPdBenef		:= aCodBenef[nCntP, 16 ] //-- Todas as verbas dos beneficiarios
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Busca todas a verbas de pensao da rescisao              	 ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							For nCntP2:= 1 To Len(cCodPdBenef) Step 6
								
								cCodVerba	:= substr(cCodPdBenef,nCntP2+3,3)
								dbSelectArea( "SRR" )
								
								If dbSeek( aChaveBusca[nBusca] + cCodVerba ) .And. Eval(cAcessaSRR)
									nValBenef	+= SRR->RR_VALOR
									
									If Empty(aPensPd) .Or. aScan(aPensPd, { |x| x[1] == cRoteiro .And. x[2] == SRR->RR_PERIODO .And. x[3] == SRR->RR_SEMANA .And. x[4] == SRR->RR_TIPO3 .And. x[5] == SRR->RR_DATAPAG .And. x[6] == SRR->RR_DTREF .And. x[7] == SRR->RR_PD } ) == 0
										Aadd(aPensPd, { cRoteiro, SRR->RR_PERIODO, SRR->RR_SEMANA, SRR->RR_TIPO3, SRR->RR_DATAPAG, SRR->RR_DTREF, SRR->RR_PD } )
									Endif
								EndIf
							Next nPd
							
							nPosBenef := Ascan( aValBenef, { |x| x[2] + x[3] + x[4] == aCodBenef[nCntP,10] + aCodBenef[nCntP,11] + aCodBenef[nCntP,01] } )
							
							If nPosBenef == 0
								Aadd(aValBenef, {  aCodBenef[nCntP,09],  aCodBenef[nCntP,10], aCodBenef[nCntP,11], SRR->RR_PD, nValBenef ,aCodBenef[nCntP,12],aCodBenef[nCntP,19],"SRQ",If(Len(aCodBenef[nCntP]) >= 22, aCodBenef[nCntP,22], ""),aCodBenef[nCntP,23],aCodBenef[nCntP,24]} ) 
							Else
								aValBenef[nPosBenef,5]	+= 	nValBenef
							EndIf
							
							If ( FunName() == "GPEM650" ) .AND. lRatItm //se geracao de titulo e rateio por Item
								fRatPensao(RetSqlName("SRR"), "RR_", SRR->RR_PD, dDataDe, dDataAte, SRA->RA_FILIAL, SRA->RA_MAT)
							EndIf
							
							nValBenef		:= 0
			
						Next nCntP
						
						dbSelectArea("SRG")
					EndIf				
				EndIf
			EndIf
		Else
			// Movimento Aberto
			dbSelectArea( "SRC" )
			dbSetOrder( 8 )
			If lImprFunci // Busca Liquido

				If SRC->(dbSeek(SRA->RA_FILIAL + SRA->RA_MAT + cVerbaBusca + cRoteiro))  .And. Eval(cAcessaSRC)
					While !Eof() .And. ( Alltrim(SRA->RA_FILIAL + SRA->RA_MAT + cVerbaBusca + cRoteiro) = ;
						AllTrim(SRC->RC_FILIAL + SRC->RC_MAT + SRC->RC_PD + SRC->RC_ROTEIR) )
						If SRC->RC_DATA >= dDataDe .And. SRC->RC_DATA <= dDataAte
							nValLiq += SRC->RC_VALOR
							If !Empty(cVerba)
								nValVrb += SRC->RC_VALOR
							EndIf
							
							If ( FunName() == "GPEM650" ) .AND. lRatItm //se geracao de titulo e rateio por Item
								fRatPensao(RetSqlName("SRC"), "RC_", SRC->RC_PD, dDataDe, dDataAte, SRA->RA_FILIAL, SRA->RA_MAT)
							EndIf
						EndIf
						dbSkip()
					EndDo
				EndIf
			EndIf

			If lImprBenef // Busca beneficios
				fBusCadBenef(@aCodBenef, cRoteiro,,.T.) 
				If cTipoRot $ "1/2/5/6/F"  // FOL/ADI/131/132/PLR (Roteiros que tem pensao)
					For nCntP := 1 To Len(aCodBenef)
						For nCntP2 := 1 To 3
							nPosVb := If( nCntP2 == 1, 1,If( nCntP2 == 2, 8, 7 ) ) // 1-Pensao Folha   2-Pensao PLR 3-Pensao Dif.13sal.
							If dbSeek(SRA->RA_FILIAL + SRA->RA_MAT + aCodBenef[nCntP,nPosVb] + cRoteiro) .And. Eval(cAcessaSRC)
								While !Eof() .And. ( Alltrim(SRA->RA_FILIAL + SRA->RA_MAT + aCodBenef[nCntP,nPosVb] + cRoteiro) = ;
									Alltrim(SRC->RC_FILIAL + SRC->RC_MAT + SRC->RC_PD + SRC->RC_ROTEIR) )
									If (SRC->RC_DATA >= dDataDe .And. SRC->RC_DATA <= dDataAte) .And.;
									   PosSrv(SRC->RC_PD,SRC->RC_FILIAL,"RV_TIPOCOD") == "2"
									   
									   	If Empty(aPensPd) .Or. SRC->RC_TIPO2 # "G" .Or. aScan(aPensPd, { |x| x[2] == SRC->RC_PERIODO .And. x[3] == SRC->RC_SEMANA .And. x[5] == SRC->RC_DATA .And. x[7] == SRC->RC_PD }) == 0
											
											nPosBenef := Ascan( aValBenef, { |x| x[2]+x[3] == aCodBenef[nCntP,10]+aCodBenef[nCntP,11]+aCodBenef[nCntP,12]+aCodBenef[nCntP,01] } )
											If nPosBenef == 0
												Aadd(aValBenef, {  aCodBenef[nCntP,09],  aCodBenef[nCntP,10], aCodBenef[nCntP,11], SRC->RC_PD, SRC->RC_VALOR,aCodBenef[nCntP,12],aCodBenef[nCntP,19],"SRQ", If(Len(aCodBenef[nCntP]) >= 22, aCodBenef[nCntP,22], ""),aCodBenef[nCntP,23],aCodBenef[nCntP,24]  } ) 					
											Else
												aValBenef[nPosBenef,5] += SRC->RC_VALOR
											EndIf
											
											If ( FunName() == "GPEM650" ) .AND. lRatItm //se geracao de titulo e rateio por Item
												fRatPensao(RetSqlName("SRC"), "RC_", SRC->RC_PD, dDataDe, dDataAte, SRA->RA_FILIAL, SRA->RA_MAT)
											EndIf
										EndIf
									EndIf
									dbSkip()
								EndDo
							EndIf
						Next nCntP2
					Next nCntP 
				Else  
					For nCntP := 1 To Len(aCodBenef)
						If dbSeek(SRA->RA_FILIAL + SRA->RA_MAT + aCodBenef[nCntP,1] + cRoteiro) .And. Eval(cAcessaSRC)
							While !Eof() .And. ( Alltrim(SRA->RA_FILIAL + SRA->RA_MAT + aCodBenef[nCntP,1] + cRoteiro) = ;
								Alltrim(SRC->RC_FILIAL + SRC->RC_MAT + SRC->RC_PD + SRC->RC_ROTEIR) )
								If (SRC->RC_DATA >= dDataDe .And. SRC->RC_DATA <= dDataAte) .And.;
								    PosSrv(SRC->RC_PD,SRC->RC_FILIAL,"RV_TIPOCOD") == "2"
									
									If Empty(aPensPd) .Or. SRC->RC_TIPO2 # "G" .Or. aScan(aPensPd, { |x| x[2] == SRC->RC_PERIODO .And. x[3] == SRC->RC_SEMANA .And. x[5] == SRC->RC_DATA .And. x[7] == SRC->RC_PD }) == 0	
										nPosBenef := Ascan( aValBenef, { |x| x[2]+x[3] == aCodBenef[nCntP,10]+aCodBenef[nCntP,11]+aCodBenef[nCntp,12]+aCodBenef[nCntp,01]  } ) 
										If nPosBenef == 0
											Aadd(aValBenef, {  aCodBenef[nCntP,09],  aCodBenef[nCntP,10], aCodBenef[nCntP,11], SRC->RC_PD, SRC->RC_VALOR,aCodBenef[nCntP,12],aCodBenef[nCntP,19],"SRQ", If(Len(aCodBenef[nCntP]) >= 22, aCodBenef[nCntP,22], "") } ) 
										Else
											aValBenef[nPosBenef,5] += SRC->RC_VALOR
										EndIf
										
										If ( FunName() == "GPEM650" ) .AND. lRatItm //se geracao de titulo e rateio por Item
											fRatPensao(RetSqlName("SRC"), "RC_", SRC->RC_PD, dDataDe, dDataAte, SRA->RA_FILIAL, SRA->RA_MAT)
										EndIf
									EndIf
								Endif
								dbSkip()
							EndDo
						Endif
						lResArea := .T.
					Next nCntP
				EndIf
			EndIf
	
			// Movimento Fechado  
			dbSelectArea( "SRD" )
			dbSetOrder( 6 )
			If lImprFunci // Busca Liquido
				If dbSeek(SRA->RA_FILIAL + SRA->RA_MAT + cVerbaBusca + cRoteiro) .And. Eval(cAcessaSRD)
					While !Eof() .And. ( Alltrim(SRA->RA_FILIAL + SRA->RA_MAT + cVerbaBusca + cRoteiro) = ;
						Alltrim(SRD->RD_FILIAL + SRD->RD_MAT + SRD->RD_PD + SRD->RD_ROTEIR) )
						If SRD->RD_DATPGT >= dDataDe .And. SRD->RD_DATPGT <= dDataAte
							nValLiq += SRD->RD_VALOR
							If !Empty(cVerba)
								nValVrb += SRD->RD_VALOR
							EndIf
							
							If ( FunName() == "GPEM650" ) .AND. lRatItm //se geracao de titulo e rateio por Item
								fRatPensao(RetSqlName("SRD"), "RD_", SRD->RD_PD, dDataDe, dDataAte, SRA->RA_FILIAL, SRA->RA_MAT)
							EndIf
						EndIf
						dbSkip()
					EndDo
				EndIf
			EndIf
			
			If lImprBenef // Busca beneficios
				fBusCadBenef(@aCodBenef,cRoteiro,, .T.) //"FOL"
				For nCntP := 1 To Len(aCodBenef)
					For nCntP2 := 1 To 3
						nPosVb := If( nCntP2 == 1, 1,If( nCntP2 == 2, 8, 7 ) ) // 1-Pensao Folha   2-Pensao PLR 3-Pensao Dif.13sal.
						dbSelectArea( "SRD" )
						dbSetOrder( 6 )
						If dbSeek(SRA->RA_FILIAL + SRA->RA_MAT + aCodBenef[nCntP,nPosVb] + cRoteiro) .And. Eval(cAcessaSRD)
							While !Eof() .And. ( Alltrim(SRA->RA_FILIAL + SRA->RA_MAT + aCodBenef[nCntP,nPosVb] + cRoteiro) = ;
								Alltrim(SRD->RD_FILIAL + SRD->RD_MAT + SRD->RD_PD + SRD->RD_ROTEIR) )
								If (SRD->RD_DATPGT >= dDataDe .And. SRD->RD_DATPGT <= dDataAte) .And.;
								   PosSrv(SRD->RD_PD,SRD->RD_FILIAL,"RV_TIPOCOD") == "2"
									
									If Empty(aPensPd) .Or. SRD->RD_TIPO2 # "G" .Or. aScan(aPensPd, { |x| x[2] == SRD->RD_PERIODO .And. x[3] == SRD->RD_SEMANA .And. x[5] == SRD->RD_DATPGT .And. x[7] == SRD->RD_PD }) == 0
										
										nPosBenef := Ascan( aValBenef, { |x| x[2]+x[3] == aCodBenef[nCntP,10]+aCodBenef[nCntP,11]+aCodBenef[nCntP,12]+aCodBenef[nCntP,01] } )
										If nPosBenef == 0
											Aadd(aValBenef, {  aCodBenef[nCntP,09],  aCodBenef[nCntP,10], aCodBenef[nCntP,11], SRD->RD_PD, SRD->RD_VALOR,aCodBenef[nCntP,12],aCodBenef[nCntP,19],"SRQ", If(Len(aCodBenef[nCntP]) >= 22, aCodBenef[nCntP,22], ""),aCodBenef[nCntP,23],aCodBenef[nCntP,24] } ) 
										Else
											aValBenef[nPosBenef,5] += SRD->RD_VALOR
										EndIf
										
										If ( FunName() == "GPEM650" ) .AND. lRatItm //se geracao de titulo e rateio por Item
											fRatPensao(RetSqlName("SRD"), "RD_", SRD->RD_PD, dDataDe, dDataAte, SRA->RA_FILIAL, SRA->RA_MAT)
										EndIf
									EndIf
								EndIf
								dbSkip()
							EndDo
						EndIf
					Next nCntP2
				Next nCntP
			EndIf              
		EndIf
		
	Next nRoteiro      
	
	If nValVrb > 0
		nValLiq := nValVrb
	EndIf

Return( Nil )
