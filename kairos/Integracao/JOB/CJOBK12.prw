#INCLUDE "TOTVS.CH"           

//016299

/*/{Protheus.doc} CJOBK12
JOB de processamento do CNAB de validação bancária
@author Carlos Henrique
@since 31/05/2019
@version undefined
@type function
/*/ 
User Function CJOBK12()
Local _lJob		:= GetRemoteType() == -1 // Verifica se é job
Local _cProcesso:= "CJOBK12JOB"
Local lProCNAB  := .F.
//Local dGetRef   := dDataBase
//Local dBkpDta	:= dDataBase

Begin Sequence

	If _lJob
		dDataBase:= MV_PAR01  //Data do parametro do SCHEDULE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK12] Iniciando processamento via schedule.")
		CONOUT("Empresa:" + CEMPANT )
		CONOUT("Filial :" + CFILANT )
		CONOUT("Data   :" + DTOC(dDataBase) )
		lProCNAB  := .T.
	else

		/*DEFINE MSDIALOG oDlg TITLE "CNAB de validação bancária" From 000,000 to 085,280 COLORS 0, 16777215 PIXEL

		@ 006, 009 SAY oSay PROMPT "Data de Validação:" SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 005,084 MSGET oGet VAR dGetRef SIZE 045,011 OF oDlg COLORS 0, 16777215 PIXEL
		@ 022,093 BUTTON oButtonOK PROMPT "OK" SIZE 034,013 OF oDlg PIXEL Action(lProCNAB:= .T., oDlg:End())
		@ 022,054 BUTTON oButtonCancel PROMPT "Cancela" SIZE 034,013 OF oDlg PIXEL Action(lProCNAB:= .F., oDlg:End())

		ACTIVATE MSDIALOG oDlg CENTERED

		IF lProCNAB
			dDataBase:= dGetRef
		ENDIF*/

		msgYesNo("Deseja gerar CNAB de validação bancária?", "Atenção")

	Endif

	if lProCNAB

		If !LockByName(_cProcesso,.T.,.T.)
			If _lJob
				CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][ "+_cProcesso+" ] Já existe um processamento em execução, aguarde!")
			Else
				MSGINFO("Já existe um processamento em execução, aguarde! "+CRLF+" Processo: "+_cProcesso)
			Endif
			Break
		Endif

		If !_lJob
			//Processo em tela
			FWMsgRun(,{|| CJOBK12PRC(_lJob) },,"Gerando CNAB de validação bancária, aguarde...")
		Else
			//Processo em JOB
			CJOBK12PRC(_lJob)
		Endif

		UnLockByName(_cProcesso,.T.,.T.)


		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK12] Processamento finalizado.")

	ENDIF

End Sequence

//dDataBase:= dBkpDta

Return Nil

/*/{Protheus.doc} CJOBK12PRC
Rotina de processamento do CNAB agutinado por banco + Tratamento TJ 
@author Carlos Henrique
@since 14/11/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJOBK12PRC(_lJob)
Local _dDataRef:= If(Type("dDataBase")=="D",dDataBase,Date())
Local _cTabBco := GetNextAlias()
Local _cTabSRA := ""
Local _cDirArq := ""
Local _CondWhr := ""
Private _aLogCVb := {}
Private _aTitCVb := {}

BeginSql Alias _cTabBco
	SELECT DISTINCT SUBSTRING(RCC.RCC_CONTEU,21,3) AS BANCO
		,SUBSTRING(RCC.RCC_CONTEU,24,5) AS AGENCIA
		,SUBSTRING(RCC.RCC_CONTEU,30,12) AS CONTA
		,SUBSTRING(RCC.RCC_CONTEU,50,12) AS ARQCFG
		,SUBSTRING(RCC.RCC_CONTEU,62,100) AS PATH
	FROM %TABLE:RCC% RCC
	WHERE RCC_FILIAL=%xfilial:RCC%
	AND RCC.RCC_FILIAL = %xfilial:RCC%
	AND RCC.RCC_CODIGO='S052'
	AND RCC.D_E_L_E_T_ = ' '
EndSql

//GETLastQuery()[2]
While (_cTabBco)->(!EOF())

	IF (_cTabBco)->BANCO == "237"
		_CondWhr:= "AND LEFT(RA_BCDEPSA,3) NOT IN ('341','001','033','104')"
	ELSE
		_CondWhr:= "AND LEFT(RA_BCDEPSA,3)='"+ (_cTabBco)->BANCO +"'"
	ENDIF	

	_CondWhr:= "%" + _CondWhr + "%"

	_cTabSRA := GetNextAlias()

	BeginSql Alias _cTabSRA
		SELECT * FROM %TABLE:SRA% SRA
		WHERE RA_FILIAL=%xfilial:SRA%
		AND RA_XVALIBC='1'			
		AND SRA.D_E_L_E_T_=' '
		%Exp:_CondWhr%
	EndSql	
	
	if (_cTabSRA)->(!EOF())

		_cDirArq := STRTRAN(TRIM((_cTabBco)->PATH),"APROVACAO","REMESSA") 

		Pergunte("XGPEM080R1", .F.)

		MV_PAR01   := "FOL"     					            //  Roteiros
		// MV_PAR02        										//  Roteiros
		// MV_PAR03        										//  Roteiros
		MV_PAR04   := "        "   								//  Filial  De
		MV_PAR05   := "ZZZZZZZZ"   								//  Filial  Ate
		MV_PAR06   := "         "     							//  Centro de Custo De
		MV_PAR07   := "ZZZZZZZZZ"     							//  Centro de Custo Ate
		MV_PAR08   := "        "  								//  Banco /Agencia De
		MV_PAR09   := "ZZZZZZZZ"  								//  Banco /Agencia Ate
		MV_PAR10   := "      "   								//  Matricula De
		MV_PAR11   := "ZZZZZZ"     								//  Matricula Ate
		MV_PAR12   := "                              "     		//  Nome De
		MV_PAR13   := "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"     		//  Nome Ate
		MV_PAR14   := "            "  							//  Conta Corrente De
		MV_PAR15   := "ZZZZZZZZZZZZ"  							//  Conta Corrente Ate
		MV_PAR16   := " ADFT"        							//  Situacao
		MV_PAR17   := 2     									//  Layout  cnab modelo 2
		MV_PAR18   := (_cTabBco)->ARQCFG             		        //  Arquivo de configuracao
		MV_PAR19   := _cDirArq      							//  nome do arquivo de saida
		MV_PAR20   := _dDataRef									//  data de credito
		MV_PAR21   := _dDataRef		  							//  Data de Pagamento De
		MV_PAR22   := _dDataRef									//  Data de Pagamento Ate
		MV_PAR23   := "ACDEGHIJMPST***"    						//  Categorias
		MV_PAR24   := 3     									//  Imprimir 1-Funcionarios 2-Beneficiarias 3-Ambos
		MV_PAR25   := _dDataRef									//  Data de Referencia
		MV_PAR26   := "*"     									//  Selecao de Processos
		MV_PAR27   := ""       									//  Selecao de Processos
		MV_PAR28   := " "     									//  Numero do Pedido     -- SUBSTITUIDO PELO NUMERO DO PEDIDO
		MV_PAR29   := 2     									//  Linha Vazia no Fim do Arquivo 1=Sim 2=Nao
		MV_PAR30   := AvKey((_cTabBco)->BANCO,"EE_CODIGO")        	//  Processar Banco
		MV_PAR31   := AvKey((_cTabBco)->AGENCIA,"EE_AGENCIA")       //  Agencia
		MV_PAR32   := AvKey((_cTabBco)->CONTA,"EE_CONTA")         	//  Conta
		MV_PAR33   := 3   										//  Gerar Conta Tipo   1=Conta corrente 2=Conta Poupanca 3=Ambas

		IF (_cTabBco)->BANCO="237"
			MV_PAR34   := 1			    						//  DOC Outros Bancos  1=Sim 2=Não
		ELSE
			MV_PAR34   := 2			    						//  DOC Outros Bancos  1=Sim 2=Não
		ENDIF	

		MV_PAR35   := 2											//  Validar Cta Bancarias R$ 0.01?  1=Nao  2=Sim
		MV_PAR36   := ctod("01/01/1900")						//  Data de admissao de
		MV_PAR37   := ctod("01/01/2999")							//  Data de admissao Fim
		MV_PAR38   := 1          								//  Cnab Exclusivo para cliente especifico ? 1= Não, 2=Sim

		U_CGPER04(.T.)

	(_cTabSRA)->(dbSkip())
	End

	(_cTabSRA)->(dbcloseArea())

(_cTabBco)->(dbSkip())
End

(_cTabBco)->(dbcloseArea())


If !(_lJob) .And. MsgYesNo("Deseja visualizar os movimentos ?","Atencao!")
	fMakeLog(_aLogCVb,_aTitCVb,,.T., "CJOBK12/" + DtoS(DDATABASE) ,"Log CNAB de validação bancária." ,"M","P",,.F.)	
EndIf

RETURN

/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
Static Function Scheddef()
	Local aParam := {"P","CJOBK12","",{},""}
Return aParam
