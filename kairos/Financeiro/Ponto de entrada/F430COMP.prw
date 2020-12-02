#Include 'Protheus.ch'

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} F430COMP
Ponto de entrada para tratamento complementar após a leitura do retorno de pagamento CNAB
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function F430COMP()
Local aArea			:= GETAREA()
LOCAL cBkpRPG		:= ""
Local aAuxArq		:= {}
Local cDrive		:= ""
Local cDir			:= ""
Local cNome			:= ""
Local cExt			:= ""
Local lMovArq		:= .F.
Local cArqRet		:= ""

//Tratamento de retorno do pagamento de bolsa auxílio e 1 centavo
IF "SPBA" $ MV_PAR03

	cArqRet	:= MV_PAR03

	//Realiza a Baixa do Título e retorno de ocorrências para o Kairós
	lMovArq:= U_CFINA96(mv_par05,mv_par06,mv_par07)	

	IF lMovArq

		SplitPath(cArqRet, @cDrive, @cDir, @cNome, @cExt )

		cBkpRPG	:= cDir + "\backup\"
		
		IF FILE(cArqRet)
			aAuxArq:= StrTokArr(cArqRet,"\",.F.)
			IF !EMPTY(aAuxArq)
				//Move arquivo para o diretorio de backup			
				If __CopyFile(cArqRet,cBkpRPG+aAuxArq[LEN(aAuxArq)])
					//Fecha arquivo e elimina
					If nHdlBco > 0
						FCLOSE(nHdlBco)
						FERASE(cArqRet)
					Endif				
				EndIF			
			ENDIF	
		ENDIF	
		
	ENDIF

	IF MSGYESNO("Deseja Imprimir o Relatório das Ocorrencias do Retorno ? ")
		U_CFINR088(.t.)	// IMPRIME o Relatório das Ocorrencias do Retorno Bancario
	EndIF

ELSE
	cBkpRPG:= TRIM(SuperGetMv("CI_BKPRPG",.F.,"\arq_txt\tesouraria\cnab\pagfor\ret\backup\"))

	// Executa rotina de contabilização especifica
	U_CFINE34(2)

	IF FILE(MV_PAR03)
		//Tratamento para o banco bradesco
		IF MV_PAR05=="237"
			aAuxArq:= StrTokArr(MV_PAR03,"\",.F.)
			IF !EMPTY(aAuxArq)
				//Move arquivo para o diretorio de backup			
				If __CopyFile(MV_PAR03,cBkpRPG+aAuxArq[LEN(aAuxArq)])
					//Fecha arquivo e elimina
					If nHdlBco > 0
						FCLOSE(nHdlBco)
						FERASE(MV_PAR03)
					Endif				
					U_CFINR75(.T.,cBkpRPG+aAuxArq[LEN(aAuxArq)],MV_PAR04,MV_PAR05,MV_PAR06,MV_PAR07,MV_PAR08)								
				EndIF			
			ENDIF	
		ENDIF
	ENDIF
ENDIF


RESTAREA(aArea)

Return
