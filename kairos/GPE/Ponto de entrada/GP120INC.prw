#INCLUDE "PROTHEUS.CH"

 /*/{Protheus.doc} GP120INC
Ponto de entrada na gravação e campos de usuário na tabela SRD
@author carlos.henrique
@since 06/11/2019
@version undefined
@type User function
/*/
User Function GP120INC()
Local aArea1:= GetArea()
Local aArea2:= SRA->(GetArea())
Local aArea3:= SRV->(GetArea())

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK02] PE GP120INC SRD")

SRD->RD_DATPGT := (cAliasSRC)->RC_DTREF  //Ajusta para gerar o cnab corretamente 
SRD->RD_DTREF  := (cAliasSRC)->RC_DTREF
SRD->RD_XIDFOL := (cAliasSRC)->RC_XIDFOL 
SRD->RD_XIDCNT := (cAliasSRC)->RC_XIDCNT 
SRD->RD_XIDLOC := (cAliasSRC)->RC_XIDLOC 
SRD->RD_XDESCPD:= POSICIONE("SRV",1,xFilial("SRV")+(cAliasSRC)->RC_PD,"RV_DESC")
SRD->RD_XNOME  := POSICIONE("SRA",1,xFilial("SRA")+(cAliasSRC)->RC_MAT,"RA_NOME")

Restarea(aArea3)
Restarea(aArea2)
Restarea(aArea1)
Return
