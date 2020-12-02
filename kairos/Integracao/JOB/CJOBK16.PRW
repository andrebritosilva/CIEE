#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CJOBK16
JOB de importação e atualização de unidades do Kairós
@author danilo.grodzicki
@since 25/11/2019
@version 12.1.25
@type function
/*/
User function CJOBK16()

Local cEmpInt := CEMPANT
Local cFilInt := CFILANT
Local nOpca   := 1

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK16] Iniciando processamento via schedule.")

IF !LockByName("CJOBK16",.T.,.T.)
	nOpca := 0
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK16] Já existe um processamento em execução, aguarde!")
ENDIF

IF nOpca > 0
	
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK16] Processo Iniciado para "+cEmpInt+"-"+cFilInt)
	
	DbSelectArea("ZCN")
	ZCN->(DbSetOrder(01))   
	
	U_C6A95PRO( 1, 29999)
	
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK16] Processo Finalizado para "+cEmpInt+"-"+cFilInt)
	
	UnLockByName("CJOBK16",.T.,.T.)
ENDIF

RETURN

/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function Scheddef()
Local aParam := {"P","CJOBK16","",{},""}
Return aParam