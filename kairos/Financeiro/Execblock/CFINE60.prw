#include "protheus.ch"

/*/{Protheus.doc} CFINE60
	Ajusta campo xvalibc e xtitvld na tabela sra na exclusao do titulo
@author felipe ortega
@since 16/11/2020
@version 1.0
@return ${return}, ${return_description}
@param cNumTit, characters, numero do titulo sendo excluido
@type function
/*/
user function CFINE60(cNumTit)

    local cQuery    := ""
    local cTab      := getnextalias()

    cQuery += "SELECT DISTINCT RA.R_E_C_N_O_ RECNO " + CRLF
	cQuery += "FROM " + RetSqlName("SRA") + " RA " + CRLF
	cQuery += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
	cQuery += " AND RA.RA_XTITVLD = '" + cNumTit + "' " + CRLF
	cQuery += " AND RA.D_E_L_E_T_ = ' ' " + CRLF

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTab,.T.,.T.)

	if (cTab)->(!EOF())

        dbSelectArea("SRA")

        BEGIN TRANSACTION

        while (cTab)->(!EOF())

            SRA->(dbgoto((cTab)->RECNO))

            if alltrim(SRA->RA_XTITVLD) == cNumTit

                reclock("SRA", .F.)

                SRA->RA_XVALIBC := '1'
                SRA->RA_XTITVLD := ''

                SRA->(msunlock())

            endif

            (cTab)->(dbSkip())

        enddo

        END TRANSACTION
    
    endif

return
