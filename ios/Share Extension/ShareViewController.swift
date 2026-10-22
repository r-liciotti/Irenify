import receive_sharing_intent

/// Share Extension di Da Mirtilla (F5): riceve il link o il video condiviso, lo
/// salva nell'App Group e riapre l'app, che avvia l'importazione. Volutamente
/// minima: le extension di condivisione hanno circa 120 MB di memoria.
class ShareViewController: RSIShareViewController {
    // iOS 26: la barra di navigazione di SLComposeServiceViewController va in
    // crash nell'impaginazione (NSInternalInconsistencyException sui vincoli,
    // https://developer.apple.com/forums/thread/805268). Nasconderla evita il
    // crash; la finestra resta comunque visibile solo un attimo, perché
    // l'extension riapre subito l'app.
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func isContentValid() -> Bool {
        navigationController?.navigationBar.isHidden = true
        return super.isContentValid()
    }
}
