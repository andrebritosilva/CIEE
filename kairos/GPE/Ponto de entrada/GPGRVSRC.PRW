#INCLUDE "PROTHEUS.CH"

 /*/{Protheus.doc} GPGRVSRC
Ponto de entrada na gravação da tabela SRC
@author carlos.henrique
@since 06/11/2019
@version undefined
@type User function
/*/
User Function GPGRVSRC()
Local aArea := GetArea()

//Tratamento para gravar o id da folha, contrato e local do contrato Kairos na SRC 
IF IsInCallStack("U_CJBK02CAL") .OR. IsInCallStack("U_CJBK15CAL")
    CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"] PE GPGRVSRC")
    RecLock("SRC",.F.) 
    SRC->RC_DATA  := DDATABASE  //Ajusta para gerar o cnab corretamente
    SRC->RC_DTREF := DDATABASE
    SRC->RC_XIDFOL:= ZC7->ZC7_IDFOL
    SRC->RC_XIDCNT:= ZC7->ZC7_IDCNTT
    SRC->RC_XIDLOC:= ZC7->ZC7_IDLOCC
    MsUnlock()
ENDIF

Restarea(aArea)
Return
