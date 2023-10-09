/*
+----------------------------------------------------------------------------+
!                         FICHA TECNICA DO PROGRAMA                          !
+------------------+---------------------------------------------------------+
!Tipo              ! Webservice                                              !
+------------------+---------------------------------------------------------+
!Modulo            ! COM - Compras                                           !
+------------------+---------------------------------------------------------+
!Nome              ! WSCOM02                                                 !
+------------------+---------------------------------------------------------+
!Descricao         ! Rotina criada para incluir, alterar, excluir e consultar!
!                  ! um Produto                                              !
+------------------+---------------------------------------------------------+
!Autor             ! Rodrigo L P Araujo                                      !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 02/05/2023                                              !
+------------------+---------------------------------------------------------+
*/
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"

#DEFINE PATHLOGSW  GetSrvProfString("Startpath","") + "\ws_log\"

User Function WSCOM02()
	IF !ExistDir(PATHLOGSW)
		MakeDir(PATHLOGSW)
	EndIF
Return

WSRESTFUL Produtos DESCRIPTION 'Cadastro de Produtos API' SECURITY 'MATA120' FORMAT "application/json,text/html" 
	WSDATA numero As Character

    WSMETHOD GET ConsultarProduto;
	DESCRIPTION "Consultar Cadastro de Produtos" ;
	WSSYNTAX "/Produtos/ConsultarProduto/{numero}";
	PATH "/Produtos/ConsultarProduto";
	PRODUCES APPLICATION_JSON	

    WSMETHOD POST CriarProduto ; 
    DESCRIPTION "Criar Cadastro de Produtos" ;
    WSSYNTAX "/Produtos/CriarProduto" ;
    PATH "/Produtos/CriarProduto";
	PRODUCES APPLICATION_JSON

    WSMETHOD PUT AlterarProduto ; 
    DESCRIPTION "Alterar Cadastro de Produtos" ;
    WSSYNTAX "/Produtos/AlterarProduto" ;
    PATH "/Produtos/AlterarProduto";
	PRODUCES APPLICATION_JSON

    WSMETHOD DELETE ExcluirProduto ; 
    DESCRIPTION "Excluir Cadastro de Produtos" ;
    WSSYNTAX "/Produtos/ExcluirProduto/{numero}" ;
    PATH "/Produtos/ExcluirProduto";
	PRODUCES APPLICATION_JSON

ENDWSRESTFUL

/*
método GET - Consulta Cadastro de Produtos
exemplo: http://localhost:3000/rest/Produtos/ConsultarProduto?numero=000001
*/
WSMETHOD GET ConsultarProduto QUERYPARAM numero WSREST Produtos
	Local lRet      := .T.
	Local aData     := {}
	Local oData     := NIL
	Local oAlias    := GetNextAlias()
	Local cProduto  := Self:numero

    FwLogMsg("INFO",, "ConsultarProduto", "WSCOM02", "", "01", "Iniciando...")

	if Empty(cProduto)
		Self:SetResponse('{"codigoProduto":"' + cProduto + '", "infoMessage":"", "errorCode":"404", "errorMessage":"Codigo do Produto não informado"}')
		Return(.F.)
	EndIF

	BeginSQL Alias oAlias
        SELECT *
        FROM %Table:SB1% SB1
        WHERE SB1.B1_FILIAL = %xFilial:SB1%
            AND SB1.%NotDel%
            AND B1_COD = %exp:cProduto%
		ORDER BY B1_COD
	EndSQL

	dbSelectArea(oAlias)
	(oAlias)->(dbGoTop())

	IF (oAlias)->(!Eof())
		oData := JsonObject():New()

		oData[ 'codigoProduto' ] := Alltrim((oAlias)->B1_COD)
		oData[ 'descricao' ]     := Alltrim((oAlias)->B1_DESC)
		oData[ 'tipo' ]          := Alltrim((oAlias)->B1_TIPO)
		oData[ 'unidadeMedida' ] := Alltrim((oAlias)->B1_UM)
		oData[ 'armazemPadrao' ] := Alltrim((oAlias)->B1_LOCPAD )
		oData[ 'codigoNCM' ]     := Alltrim((oAlias)->B1_POSIPI )

        aAdd(aData,oData)

		//Define o retorno do método
		Self:SetResponse(FwJsonSerialize(aData))

	ELSE
		Self:SetResponse('{"codigoProduto":"'+cProduto+'", "infoMessage":"", "errorMessage":"Codigo do Produto não encontrado"}') 
		lRet    := .F.
	EndIF

	FreeObj(oData)
	(oAlias)->(dbCloseArea())

    FwLogMsg("INFO",, "ConsultarProduto", "WSCOM02", "", "01", "FIM...")

Return(lRet)

/*
método POST - Criar Cadastro de Produtos
exemplo: http://localhost:3000/rest/Produtos/CriarProduto
*/
WSMETHOD POST CriarProduto WSSERVICE Produtos
	Local lRet       := .T.
	Local oJson      := Nil
	Local cJson      := Self:GetContent()
	Local cError     := ""
    Local cProduto   := ""
    Local cDescricao := ""
    Local cTipo      := ""
    Local cArmazem   := ""
    Local cUOM       := ""
    Local cNCM       := ""
    Local aItem      := {}

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.

	//Se não existir o diretório de logs dentro da Protheus Data, será criado
	IF !ExistDir(PATHLOGSW)
		MakeDir(PATHLOGSW)
	EndIF

    FwLogMsg("INFO",, "CriarProduto", "WSCOM02", "", "01", "Iniciando...")

	//Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
	Self:SetContentType("application/json")
	oJson   := JsonObject():New()
	cError  := oJson:FromJson(cJson)

	//Se tiver algum erro no Parse, encerra a execução
	IF !Empty(cError)
		FwLogMsg("ERROR",, "CriarProduto", "WSCOM02", "", "01", 'Parser Json Error')
        Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"500" ,  "errorMessage":"Parser Json Error" }')
		lRet    := .F.
	Else
        //Lendo o arquivo JSON
		cProduto   := PadR(oJson:GetJsonObject( 'codigoProduto' )   ,TamSX3("B1_COD")[1])
		cDescricao := PadR(oJson:GetJsonObject( 'descricao' )       ,TamSX3("B1_DESC")[1])
		cTipo      := PadR(oJson:GetJsonObject( 'tipo' )            ,TamSX3("B1_TIPO")[1])
		cArmazem   := PadR(oJson:GetJsonObject( 'armazemPadrao' )   ,TamSX3("B1_UM")[1])
		cUOM       := PadR(oJson:GetJsonObject( 'unidadeMedida' )   ,TamSX3("B1_LOCPAD")[1])
		cNCM       := PadR(oJson:GetJsonObject( 'codigoNCM' )       ,TamSX3("B1_POSIPI")[1])

        //Verifica se o produto existe			    
        If (Existe("SA2",1,cProduto))
            FwLogMsg("ERROR",, "CriarProduto", "WSCOM02", "", "01", "Produto: "+ Alltrim(cProduto) +" existe!")
            Self:SetResponse('{"codigoProduto":"'+ Alltrim(cProduto) +'", "infoMessage":"", "errorCode":"500" ,  "errorMessage":"Produto existente na tabela" }')
            FreeObj(oJson)
            Return(.F.)
        Endif

        //Verifica se a NCM existe			    
        If !(Existe("SYD",1,cNCM)) .and. !Empty(cNCM)
            FwLogMsg("ERROR",, "CriarProduto", "WSCOM02", "", "01", "NCM: "+ Alltrim(cNCM) +" nao existe!")
            Self:SetResponse('{"codigoProduto":"'+ Alltrim(cProduto) +'", "infoMessage":"", "errorCode":"404" ,  "errorMessage":"NCM '+ Alltrim(cNCM) +' nao existe" }')
            FreeObj(oJson)
            Return(.F.)
        Endif

        //Verifica se o armazem existe			    
        If !(Existe("NNR",1,cArmazem)) 
            FwLogMsg("ERROR",, "CriarProduto", "WSCOM02", "", "01", "Armazem: "+ Alltrim(cArmazem) +" nao existe!")
            Self:SetResponse('{"codigoProduto":"'+ Alltrim(cProduto) +'", "infoMessage":"", "errorCode":"404" ,  "errorMessage":"Armazem '+ Alltrim(cArmazem) +' nao existe" }')
            FreeObj(oJson)
            Return(.F.)
        Endif

        aAdd(aItem, {"B1_FILIAL"    , xFILIAL("SB1"), Nil } )
        aAdd(aItem, {"B1_COD"	    , cProduto	    , NIL})
        aAdd(aItem, {"B1_DESC"      , cDescricao	, NIL})
        aAdd(aItem, {"B1_TIPO"	    , cTipo		    , NIL})
        aAdd(aItem, {"B1_UM"	    , cUOM		    , NIL})
        aAdd(aItem, {"B1_LOCPAD"	, cArmazem		, NIL})
        aAdd(aItem, {"B1_POSIPI"	, cNCM		    , NIL})

        //Executa a inclusão automática de Cadastro de Produtos
        FwLogMsg("INFO",, "CriarProduto", "WSCOM02", "", "01", "MSExecAuto")

        MSExecAuto({|x,y| mata010(x,y)},aItem,3) 

        //Se houve erro, gera um arquivo de log dentro do diretório da protheus data
        IF lMsErroAuto
            cArqLog  := "CriarProduto-" + Alltrim(cProduto) + "-" + StrTran(Time(), ':' , '-' )+".log"
            aLogAuto := {}
            aLogAuto := GetAutoGrLog()
            cError := GravaLog(cArqLog,aLogAuto)

            FwLogMsg("ERROR",, "CriarProduto", "WSCOM02", "", "01", cError )
            Self:SetResponse('{"codigoProduto":"' + Alltrim(cProduto) + '", "infoMessage":"", "errorCode":"500" ,  "errorMessage":"'+ Alltrim(cError) +'" }')
            lRet    := .F.
        ELSE
            ConfirmSX8()
            FwLogMsg("INFO",, "CriarProduto", "WSCOM02", "", "01", "Produto criado: " + cProduto)
            Self:SetResponse('{"codigoProduto":"' + Alltrim(cProduto) + '", "infoMessage":"PRODUTO CRIADO COM SUCESSO", "errorCode":"", "errorMessage":"" }')
        EndIF
    Endif

	FreeObj(oJson)
    FwLogMsg("INFO",, "CriarProduto", "WSCOM02", "", "01", "FIM...")
Return(lRet)

/*
método PUT - Alterar Cadastro de Produtos
exemplo: http://localhost:3000/rest/Produtos/AlterarProduto
*/
WSMETHOD PUT AlterarProduto WSSERVICE Produtos
	Local lRet      := .T.
	Local oJson     := Nil
    Local oItems    := Nil
	Local cJson     := Self:GetContent()
	Local cError    := ""
    Local cProduto   := ""
    Local cFornLoja := ""
    Local cFornece  := ""
    Local cLoja     := ""
    Local cItem     := ""
	Local nQtde     := 0
	Local nValor    := 0
	Local nTotal    := 0
    Local aCabec    := {}
    Local aItens    := {}
    Local aItem     := {}
    Local i         := 0

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.

	//Se não existir o diretório de logs dentro da Protheus Data, será criado
	IF !ExistDir(PATHLOGSW)
		MakeDir(PATHLOGSW)
	EndIF

    FwLogMsg("INFO",, "AlterarProduto", "WSCOM02", "", "01", "Iniciando")

	//Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
	Self:SetContentType("application/json")
	oJson   := JsonObject():New()
	cError  := oJson:FromJson(cJson)

	//Se tiver algum erro no Parse, encerra a execução
	IF !Empty(cError)
		FwLogMsg("ERROR",, "AlterarProduto", "WSCOM02", "", "01", 'Parser Json Error')
        Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"500" ,  "errorMessage":"Parser Json Error" }')
		lRet    := .F.
	Else
        //Lendo o cabeçalho do arquivo JSON
        cProduto  := Alltrim(oJson:GetJsonObject('noPedido'))
        cFornLoja:= Alltrim(oJson:GetJsonObject('noFornecedor'))
		cFornece := Left(cFornLoja,6)
		cLoja    := Right(cFornLoja,2)

        //Verifica se o fornecedor existe			    
        If !(Existe("SA2",1,cFornLoja))
            FwLogMsg("ERROR",, "AlterarProduto", "WSCOM02", "", "01", "Fornecedor: "+ Alltrim(cFornLoja) +" nao existe!")
            Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"404" ,  "errorMessage":"O fornecedor '+ cFornece + " - loja " + cLoja +' nao existe" }')
            FreeObj(oJson)
            Return(.F.)
        Endif

        //Verifica se o Cadastro de Produtos existe			    
        dbSelectArea("SB1")
        SB1->(dbSetOrder(1))
        SB1->(dbGoTop())
        If SB1->(dbSeek(xFilial("SB1") + cProduto))
            //Monta o cabeçalho do Cadastro de Produtos apenas se houver itens
            aadd(aCabec,{"B1_COD"       , cProduto})
            aadd(aCabec,{"C7_EMISSAO"   , SB1->C7_EMISSAO})
            aadd(aCabec,{"C7_FORNECE"   , cFornece})
            aadd(aCabec,{"C7_LOJA"      , cLoja})
            aadd(aCabec,{"C7_COND"      , SB1->C7_COND})
            aadd(aCabec,{"C7_CONTATO"   , SB1->C7_CONTATO})
            aadd(aCabec,{"C7_FILENT"    , SB1->C7_FILENT})

            //Lendo os itens do arquivo JSON
            oItems  := oJson:GetJsonObject('items')
            IF ValType( oItems ) == "A"
                For i  := 1 To Len (oItems)
                    cItem    := oItems[i]:GetJsonObject( 'item' )
                    cProduto := PadR(AllTrim(oItems[i]:GetJsonObject( 'produto' )),TamSX3("C7_PRODUTO")[1])
                    nQtde    := oItems[i]:GetJsonObject( 'quantidade' )
                    nValor   := oItems[i]:GetJsonObject( 'precoUnitario' )
                    nTotal   := nQtde * nValor

                    //Verifica se o produto existe			    
                    If !(Existe("SB1",1,cProduto))
                        FwLogMsg("ERROR",, "AlterarProduto", "WSCOM02", "", "01", "Produto: "+ Alltrim(cProduto) +" nao existe!")
                        Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"404" ,  "errorMessage":"O produto '+ Alltrim(cProduto) +' nao existe" }')
                        FreeObj(oJson)
                        Return(.F.)
                    Endif

                    aItem:= {}
                    aAdd(aItem,{"C7_ITEM"	, PADL(cItem,4,"0") , NIL})
                    aAdd(aItem,{"C7_PRODUTO", cProduto		    , NIL})
                    aAdd(aItem,{"C7_QUANT"	, nQtde		        , NIL})
                    aAdd(aItem,{"C7_PRECO"	, nValor		    , NIL})
                    aAdd(aItem,{"C7_TOTAL"	, nTotal		    , NIL})
                    aAdd(aItem,{"LINPOS"    , "C7_ITEM" ,PADL(cItem,4,"0")})
                    aadd(aItem,{"AUTDELETA"	, "N"			    , Nil})	
                    aAdd(aItens,aItem)

                Next

                //Executa a inclusão automática de Cadastro de Produtos
                FwLogMsg("INFO",, "AlterarProduto", "WSCOM02", "", "01", "MSExecAuto")
                MSExecAuto({|a,b,c,d,e| MATA120(a,b,c,d,e)},1,aCabec,aItens,4,.F.)

                //Se houve erro, gera um arquivo de log dentro do diretório da protheus data
                IF lMsErroAuto
                    cArqLog  := "AlterarProduto-" + cFornLoja + "-" + DTOS(dDataBase) + "-" + StrTran(Time(), ':' , '-' )+".log"
                    aLogAuto := {}
                    aLogAuto := GetAutoGrLog()
                    GravaLog(cArqLog,aLogAuto)

                    FwLogMsg("ERROR",, "AlterarProduto", "WSCOM02", "", "01", cErro )
                    Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"500" ,  "errorMessage":"'+ Alltrim(cErro) +'" }')
                    lRet    := .F.
                ELSE
                    FwLogMsg("INFO",, "AlterarProduto", "WSCOM02", "", "01", "Pedido alterado: " + cProduto)
                    Self:SetResponse('{"codigoProduto":"'+cProduto+'", "infoMessage":"PEDIDO ALTERADO COM SUCESSO", "errorCode":"", "errorMessage":"" }')
                EndIF

            Else
                FwLogMsg("ERROR",, "AlterarProduto", "WSCOM02", "", "01", "Item nao informado")
                Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"500" ,  "errorMessage":"Item nao informado" }')
                FreeObj(oJson)
                lRet    := .F.
            Endif 
        Else
            FwLogMsg("ERROR",, "AlterarProduto", "WSCOM02", "", "01", "Pedido: "+ Alltrim(cProduto) +" nao existe!")
            Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"404" ,  "errorMessage":"O Cadastro de Produtos '+ cProduto +' nao existe" }')
            FreeObj(oJson)
            lRet := .F.
        Endif               
    Endif

	FreeObj(oJson)
Return(lRet)

/*
método DELETE - Excluir Cadastro de Produtos
exemplo: http://localhost:3000/rest/Produtos/ExcluirProduto
*/
WSMETHOD DELETE ExcluirProduto WSSERVICE Produtos
	Local lRet      := .T.
	Local oJson     := Nil
	Local cJson     := Self:GetContent()
	Local cError    := ""
    Local cProduto   := ""
    Local cFornLoja := ""
    Local cFornece  := ""
    Local cLoja     := ""
    Local aCabec    := {}
    Local aItens    := {}

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.

	//Se não existir o diretório de logs dentro da Protheus Data, será criado
	IF !ExistDir(PATHLOGSW)
		MakeDir(PATHLOGSW)
	EndIF

    FwLogMsg("INFO",, "ExcluirProduto", "WSCOM02", "", "01", "Iniciando")

	//Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
	Self:SetContentType("application/json")
	oJson   := JsonObject():New()
	cError  := oJson:FromJson(cJson)

	//Se tiver algum erro no Parse, encerra a execução
	IF !Empty(cError)
		FwLogMsg("ERROR",, "ExcluirProduto", "WSCOM02", "", "01", 'Parser Json Error')
        Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"500" ,  "errorMessage":"Parser Json Error" }')
		lRet    := .F.
	Else
        //Lendo o cabeçalho do arquivo JSON
        cProduto  := Alltrim(oJson:GetJsonObject('noPedido'))
        cFornLoja:= Alltrim(oJson:GetJsonObject('noFornecedor'))
		cFornece := Left(cFornLoja,6)
		cLoja    := Right(cFornLoja,2)

        //Verifica se o fornecedor existe			    
        If !(Existe("SA2",1,cFornLoja))
            FwLogMsg("ERROR",, "ExcluirProduto", "WSCOM02", "", "01", "Fornecedor: "+ Alltrim(cFornLoja) +" nao existe!")
            Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"404" ,  "errorMessage":"O fornecedor '+ cFornece + " - loja " + cLoja +' nao existe" }')
            FreeObj(oJson)
            Return(.F.)
        Endif

        //Verifica se o Cadastro de Produtos existe			    
        dbSelectArea("SB1")
        SB1->(dbSetOrder(1))
        SB1->(dbGoTop())
        If SB1->(dbSeek(xFilial("SB1") + cProduto))
            //Monta o cabeçalho do Cadastro de Produtos apenas se houver itens
            aadd(aCabec,{"B1_COD"       , cProduto})
            aadd(aCabec,{"C7_FORNECE"   , cFornece})
            aadd(aCabec,{"C7_LOJA"      , cLoja})

            //Executa a inclusão automática de Cadastro de Produtos
            FwLogMsg("INFO",, "ExcluirProduto", "WSCOM02", "", "01", "MSExecAuto")
            MSExecAuto({|a,b,c,d,e| MATA120(a,b,c,d,e)},1,aCabec,aItens,5,.F.)

            //Se houve erro, gera um arquivo de log dentro do diretório da protheus data
            IF lMsErroAuto
                cArqLog  := "ExcluirProduto-" + cFornLoja + "-" + DTOS(dDataBase) + "-" + StrTran(Time(), ':' , '-' )+".log"
                aLogAuto := {}
                aLogAuto := GetAutoGrLog()                
                GravaLog(cArqLog,aLogAuto)

                FwLogMsg("ERROR",, "ExcluirProduto", "WSCOM02", "", "01", cErro )
                Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"500" ,  "errorMessage":"'+ Alltrim(cErro) +'" }')
                lRet    := .F.
            ELSE
                FwLogMsg("INFO",, "ExcluirProduto", "WSCOM02", "", "01", "Pedido Excluido: " + cProduto)
                Self:SetResponse('{"codigoProduto":"'+cProduto+'", "infoMessage":"PEDIDO EXCLUIDO COM SUCESSO", "errorCode":"", "errorMessage":"" }')
            EndIF
        Else
            FwLogMsg("ERROR",, "ExcluirProduto", "WSCOM02", "", "01", "Pedido: "+ Alltrim(cProduto) +" nao existe!")
            Self:SetResponse('{"codigoProduto":"", "infoMessage":"", "errorCode":"404" ,  "errorMessage":"O Cadastro de Produtos '+ cProduto +' nao existe" }')
            FreeObj(oJson)
            lRet := .F.
        Endif               
    Endif

	FreeObj(oJson)
Return(lRet)

//Função para consulta simples se um registro existe
//Sintaxe: Existe("SB1",1,"090100243")
//Retorno: .F. ou .T.
Static Function Existe(cTabela,nOrdem,cConteudo)
	Local lRet   := .F.

	dbSelectArea(cTabela)
	(cTabela)->(dbSetOrder(nOrdem))
	(cTabela)->(dbGoTop())
	If (cTabela)->(dbSeek(xFilial(cTabela) + cConteudo))
		lRet := .T.
	Endif
Return(lRet)

Static Function GravaLog(cArqLog,aLogAuto)
    Local i     := 0
    Local cErro := ""

    For i := 1 To Len(aLogAuto)
        cErro += EncodeUTF8(aLogAuto[i])+CRLF
    Next i

    MemoWrite(PATHLOGSW + "\" + cArqLog,cErro)
Return(cErro)
