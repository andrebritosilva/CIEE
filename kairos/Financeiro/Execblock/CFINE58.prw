#include "protheus.ch"
#INCLUDE "TBICONN.CH"

user function CFINE58()

    local cQry 		  := ""
    local cAliasZCR   := getnextAlias()

    cQry += " SELECT ZCR_NUMSEQ FROM "+RetSqlName("ZCR") + CRLF
    cQry += " WHERE " + CRLF
    cQry += " ZCR_FILIAL='"+xFilial("ZCR")+"' " + CRLF
    cQry += " AND ZCR_CONTRA='"+Alltrim(SE1->E1_XIDCNT)+"' " + CRLF
    cQry += " AND ZCR_LOCCON = '" + alltrim(SE1->E1_XIDLOC) + "' " + CRLF
    cQry += " AND D_E_L_E_T_ = ' ' "

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasZCR,.T.,.T.)

    if (cAliasZCR)->(!eof())

        U_CJBK01RC(SE1->E1_VALOR, SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_PORTADO, SE1->E1_AGEDEP, SE1->E1_CONTA, SE1->E1_VENCREA, (cAliasZCR)->ZCR_NUMSEQ, .T., SE1->E1_XCOMPET, SE1->E1_XIDCNT)

    endif

return
