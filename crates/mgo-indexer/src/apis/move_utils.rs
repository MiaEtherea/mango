// Copyright (c) MangoNet Labs Ltd.
// SPDX-License-Identifier: Apache-2.0

use std::collections::BTreeMap;

use async_trait::async_trait;
use jsonrpsee::core::RpcResult;
use jsonrpsee::http_client::HttpClient;
use jsonrpsee::RpcModule;

use mgo_json_rpc::MgoRpcModule;
use mgo_json_rpc_api::MoveUtilsClient;
use mgo_json_rpc_api::MoveUtilsServer;
use mgo_json_rpc_types::{
    MoveFunctionArgType, MgoMoveNormalizedFunction, MgoMoveNormalizedModule,
    MgoMoveNormalizedStruct,
};
use mgo_open_rpc::Module;
use mgo_types::base_types::ObjectID;

pub(crate) struct MoveUtilsApi {
    fullnode: HttpClient,
}

impl MoveUtilsApi {
    pub fn new(fullnode_client: HttpClient) -> Self {
        Self {
            fullnode: fullnode_client,
        }
    }
}

impl MgoRpcModule for MoveUtilsApi {
    fn rpc(self) -> RpcModule<Self> {
        self.into_rpc()
    }

    fn rpc_doc_module() -> Module {
        mgo_json_rpc_api::MoveUtilsOpenRpc::module_doc()
    }
}

#[async_trait]
impl MoveUtilsServer for MoveUtilsApi {
    async fn get_normalized_move_modules_by_package(
        &self,
        package: ObjectID,
    ) -> RpcResult<BTreeMap<String, MgoMoveNormalizedModule>> {
        self.fullnode
            .get_normalized_move_modules_by_package(package)
            .await
    }

    async fn get_normalized_move_module(
        &self,
        package: ObjectID,
        module_name: String,
    ) -> RpcResult<MgoMoveNormalizedModule> {
        self.fullnode
            .get_normalized_move_module(package, module_name)
            .await
    }

    async fn get_normalized_move_struct(
        &self,
        package: ObjectID,
        module_name: String,
        struct_name: String,
    ) -> RpcResult<MgoMoveNormalizedStruct> {
        self.fullnode
            .get_normalized_move_struct(package, module_name, struct_name)
            .await
    }

    async fn get_normalized_move_function(
        &self,
        package: ObjectID,
        module_name: String,
        function_name: String,
    ) -> RpcResult<MgoMoveNormalizedFunction> {
        self.fullnode
            .get_normalized_move_function(package, module_name, function_name)
            .await
    }

    async fn get_move_function_arg_types(
        &self,
        package: ObjectID,
        module: String,
        function: String,
    ) -> RpcResult<Vec<MoveFunctionArgType>> {
        self.fullnode
            .get_move_function_arg_types(package, module, function)
            .await
    }
}
