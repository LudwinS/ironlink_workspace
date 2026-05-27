mod db;
#[tokio::main]
async fn main() {
    dotenvy::dotenv().expect("Abortando, no se encontro el archivo .env en la raiz del backend");

    println!("Inicializando");
    
    let _pool = db::conn::establish_connexion().await;

    println!("Conectado con exito");
}
