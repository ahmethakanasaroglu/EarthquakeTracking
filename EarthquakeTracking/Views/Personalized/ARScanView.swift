import UIKit
import ARKit
import SceneKit
import Combine

class ARRealObjectSimulationViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PersonalizedViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // AR ve SceneKit
    private let arSceneView = ARSCNView()
    private var detectedObjects = [SCNNode]()
    private var simulationActive = false
    private var simulationTimer: Timer?
    private var currentMagnitude: Float = 5.0
    private var objectDetectionActive = false
    private var scanningTimer: Timer?
    private var scanningTimeLeft = 5
    
    // UI Bileşenleri
    private let simulationControlPanel = UIView()
    private let magnitudeSlider = UISlider()
    private let magnitudeLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let intensityLabel = UILabel()
    private let infoButton = UIButton(type: .infoLight)
    private let scanningOverlay = UIView()
    private let scanningLabel = UILabel()
    private let scanningProgressView = UIProgressView()
    private let detectObjectsButton = UIButton(type: .system)
    
    // MARK: - Initialization
    init(viewModel: PersonalizedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupARSession()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseARSession()
        stopSimulation()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "Gerçek Nesne Simülasyonu"
        view.backgroundColor = .black
        
        // AR View Setup
        arSceneView.translatesAutoresizingMaskIntoConstraints = false
        arSceneView.delegate = self
        arSceneView.automaticallyUpdatesLighting = true
        arSceneView.debugOptions = []
        view.addSubview(arSceneView)
        
        // Kontrol Paneli
        setupControlPanel()
        
        // Info Button
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        view.addSubview(infoButton)
        
        // Intensity Label
        intensityLabel.translatesAutoresizingMaskIntoConstraints = false
        intensityLabel.text = "Deprem Şiddeti: Pasif"
        intensityLabel.textColor = .white
        intensityLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        intensityLabel.textAlignment = .center
        intensityLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        intensityLabel.layer.cornerRadius = 8
        intensityLabel.clipsToBounds = true
        intensityLabel.isHidden = true
        view.addSubview(intensityLabel)
        
        // Nesne Algılama Buton
        detectObjectsButton.translatesAutoresizingMaskIntoConstraints = false
        detectObjectsButton.setTitle("Nesneleri Tanımla", for: .normal)
        detectObjectsButton.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        detectObjectsButton.backgroundColor = .systemBlue
        detectObjectsButton.tintColor = .white
        detectObjectsButton.layer.cornerRadius = 12
        detectObjectsButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        detectObjectsButton.addTarget(self, action: #selector(startObjectDetection), for: .touchUpInside)
        view.addSubview(detectObjectsButton)
        
        // Tarama Kaplama
        setupScanningOverlay()
        
        // Constraints
        NSLayoutConstraint.activate([
            arSceneView.topAnchor.constraint(equalTo: view.topAnchor),
            arSceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arSceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arSceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            simulationControlPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            simulationControlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            simulationControlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            infoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            infoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoButton.widthAnchor.constraint(equalToConstant: 44),
            infoButton.heightAnchor.constraint(equalToConstant: 44),
            
            intensityLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            intensityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            intensityLabel.widthAnchor.constraint(equalToConstant: 200),
            intensityLabel.heightAnchor.constraint(equalToConstant: 40),
            
            detectObjectsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            detectObjectsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detectObjectsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupScanningOverlay() {
        scanningOverlay.translatesAutoresizingMaskIntoConstraints = false
        scanningOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        scanningOverlay.isHidden = true
        
        scanningLabel.translatesAutoresizingMaskIntoConstraints = false
        scanningLabel.text = "Nesneleri Tarama: 5 sn"
        scanningLabel.textColor = .white
        scanningLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        scanningLabel.textAlignment = .center
        
        scanningProgressView.translatesAutoresizingMaskIntoConstraints = false
        scanningProgressView.progressTintColor = .systemBlue
        scanningProgressView.trackTintColor = .systemGray
        scanningProgressView.progress = 0.0
        
        scanningOverlay.addSubview(scanningLabel)
        scanningOverlay.addSubview(scanningProgressView)
        view.addSubview(scanningOverlay)
        
        NSLayoutConstraint.activate([
            scanningOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            scanningOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scanningOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scanningOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scanningLabel.centerXAnchor.constraint(equalTo: scanningOverlay.centerXAnchor),
            scanningLabel.centerYAnchor.constraint(equalTo: scanningOverlay.centerYAnchor),
            
            scanningProgressView.topAnchor.constraint(equalTo: scanningLabel.bottomAnchor, constant: 16),
            scanningProgressView.leadingAnchor.constraint(equalTo: scanningOverlay.leadingAnchor, constant: 40),
            scanningProgressView.trailingAnchor.constraint(equalTo: scanningOverlay.trailingAnchor, constant: -40),
            scanningProgressView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    private func setupControlPanel() {
        simulationControlPanel.translatesAutoresizingMaskIntoConstraints = false
        simulationControlPanel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        simulationControlPanel.layer.cornerRadius = 16
        view.addSubview(simulationControlPanel)
        
        // Magnitude Label
        magnitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        magnitudeLabel.text = "Deprem Büyüklüğü: 5.0"
        magnitudeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        magnitudeLabel.textAlignment = .center
        
        // Magnitude Slider
        magnitudeSlider.translatesAutoresizingMaskIntoConstraints = false
        magnitudeSlider.minimumValue = 3.0
        magnitudeSlider.maximumValue = 9.0
        magnitudeSlider.value = 5.0
        magnitudeSlider.minimumTrackTintColor = .systemBlue
        magnitudeSlider.addTarget(self, action: #selector(magnitudeChanged), for: .valueChanged)
        
        // Start Button
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Simülasyonu Başlat", for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.layer.cornerRadius = 12
        startButton.setTitleColor(.white, for: .normal)
        startButton.addTarget(self, action: #selector(toggleSimulation), for: .touchUpInside)
        startButton.isEnabled = false // İlk başta nesne tanımlanana kadar devre dışı
        
        // Reset Button
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.setTitle("Sıfırla", for: .normal)
        resetButton.backgroundColor = .systemGray
        resetButton.layer.cornerRadius = 12
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.addTarget(self, action: #selector(resetSimulation), for: .touchUpInside)
        
        // Panel Layout
        let buttonsStackView = UIStackView(arrangedSubviews: [startButton, resetButton])
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 10
        
        simulationControlPanel.addSubview(magnitudeLabel)
        simulationControlPanel.addSubview(magnitudeSlider)
        simulationControlPanel.addSubview(buttonsStackView)
        
        NSLayoutConstraint.activate([
            magnitudeLabel.topAnchor.constraint(equalTo: simulationControlPanel.topAnchor, constant: 16),
            magnitudeLabel.leadingAnchor.constraint(equalTo: simulationControlPanel.leadingAnchor, constant: 16),
            magnitudeLabel.trailingAnchor.constraint(equalTo: simulationControlPanel.trailingAnchor, constant: -16),
            
            magnitudeSlider.topAnchor.constraint(equalTo: magnitudeLabel.bottomAnchor, constant: 16),
            magnitudeSlider.leadingAnchor.constraint(equalTo: simulationControlPanel.leadingAnchor, constant: 16),
            magnitudeSlider.trailingAnchor.constraint(equalTo: simulationControlPanel.trailingAnchor, constant: -16),
            
            buttonsStackView.topAnchor.constraint(equalTo: magnitudeSlider.bottomAnchor, constant: 16),
            buttonsStackView.leadingAnchor.constraint(equalTo: simulationControlPanel.leadingAnchor, constant: 16),
            buttonsStackView.trailingAnchor.constraint(equalTo: simulationControlPanel.trailingAnchor, constant: -16),
            buttonsStackView.bottomAnchor.constraint(equalTo: simulationControlPanel.bottomAnchor, constant: -16),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupARSession() {
        arSceneView.delegate = self
    }
    
    private func setupBindings() {
        // ViewModel ile bağlantılar
        viewModel.$simulationIntensity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] intensity in
                self?.updateIntensityLabel(intensity: intensity)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - AR Session Management
    private func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arSceneView.session.run(configuration)
    }
    
    private func pauseARSession() {
        arSceneView.session.pause()
    }
    
    // MARK: - Object Detection
    @objc private func startObjectDetection() {
        objectDetectionActive = true
        scanningOverlay.isHidden = false
        detectObjectsButton.isEnabled = false
        scanningTimeLeft = 5
        
        // İlerleme çubuğunu sıfırla
        scanningProgressView.progress = 0.0
        scanningLabel.text = "Nesneleri Tarama: 5 sn"
        
        // Zamanlayıcıyı başlat
        scanningTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.scanningTimeLeft -= 1
            self.scanningProgressView.progress = Float(5 - self.scanningTimeLeft) / 5.0
            self.scanningLabel.text = "Nesneleri Tarama: \(self.scanningTimeLeft) sn"
            
            if self.scanningTimeLeft <= 0 {
                timer.invalidate()
                self.finishObjectDetection()
            }
        }
        
        // ARKit oturumunu yapılandır - gerçek nesneleri algılamak için
        configureARSessionForObjectDetection()
    }
    
    private func configureARSessionForObjectDetection() {
        // Şimdilik, basit bir dünya takibi ile kamera görüntüsünü kullanalım
        // Gerçek hayatta, ARKit'in nesne algılama özellikleri veya ML görüntü tanıma kullanılabilir
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func finishObjectDetection() {
        scanningOverlay.isHidden = true
        objectDetectionActive = false
        detectObjectsButton.isEnabled = true
        
        // Camera frame'den nesneleri yakala
        captureObjectsFromCurrentFrame()
        
        // Başlatma butonunu etkinleştir
        startButton.isEnabled = true
    }
    
    private func captureObjectsFromCurrentFrame() {
        // Gerçek hayatta, ARKit'in veya ML'nin nesne algılama özellikleri kullanılarak nesneler tanımlanabilir
        // Basitleştirilmiş bir sürüm olarak, sahnede rastgele "kutular" algılanmış gibi yapalım
        
        // Önce eski nesneleri temizle
        clearDetectedObjects()
        
        // 1.5 saniyelik basılı tutmada gerçekten nesne algılaması yapmak için ARKit'in
        // özelliklerini kullanmak gerekir; burada simüle edilmiş nesneler oluşturuyoruz
        
        // Gerçek bir masaüstü oluştur
        let tableNode = createTableSurfaceNode()
        arSceneView.scene.rootNode.addChildNode(tableNode)
        detectedObjects.append(tableNode)
        
        // Masaüstü bilgisayar
        let computerNode = createComputerNode()
        arSceneView.scene.rootNode.addChildNode(computerNode)
        detectedObjects.append(computerNode)
        
        // Kahve fincanı
        let coffeeNode = createCoffeeMugNode()
        arSceneView.scene.rootNode.addChildNode(coffeeNode)
        detectedObjects.append(coffeeNode)
        
        // Kitap
        let bookNode = createBookNode()
        arSceneView.scene.rootNode.addChildNode(bookNode)
        detectedObjects.append(bookNode)
        
        // Kalem ve defter
        let penNode = createPenNode()
        arSceneView.scene.rootNode.addChildNode(penNode)
        detectedObjects.append(penNode)
        
        // Kullanıcıya geri bildirim
        showToast(message: "\(detectedObjects.count) nesne bulundu ve simülasyona hazır")
    }
    
    private func clearDetectedObjects() {
        for objectNode in detectedObjects {
            objectNode.removeFromParentNode()
        }
        detectedObjects.removeAll()
    }
    
    // MARK: - Simulation Control
    @objc private func toggleSimulation() {
        simulationActive.toggle()
        
        if simulationActive {
            startSimulation()
        } else {
            stopSimulation()
        }
    }
    
    private func startSimulation() {
        startButton.setTitle("Simülasyonu Durdur", for: .normal)
        startButton.backgroundColor = .systemRed
        intensityLabel.isHidden = false
        
        // Nesne hareket zamanlayıcısını başlat
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.applyEarthquakeForces()
        }
        
        // Haptic geri bildirimi başlat
        startHapticFeedback()
    }
    
    private func stopSimulation() {
        simulationActive = false
        startButton.setTitle("Simülasyonu Başlat", for: .normal)
        startButton.backgroundColor = .systemGreen
        intensityLabel.isHidden = true
        
        // Zamanlayıcıyı durdur
        simulationTimer?.invalidate()
        simulationTimer = nil
        
        // Nesnelerin hareketini durdur
        stabilizeObjects()
    }
    
    @objc private func resetSimulation() {
        // Aktif simülasyonu durdur
        stopSimulation()
        
        // Algılanan nesneleri sıfırla
        clearDetectedObjects()
        
        // Etkinleştirme dışı kontrolleri sıfırla
        startButton.isEnabled = false
    }
    
    private func applyEarthquakeForces() {
        guard simulationActive else { return }
        
        // Perlin gürültüsü kullanarak gerçekçi deprem hareketi oluştur
        let time = CACurrentMediaTime()
        let xShake = Float(generatePerlinNoise(time: time, frequency: 4.0)) * currentMagnitude * 0.01
        let yShake = Float(generatePerlinNoise(time: time + 100, frequency: 3.0)) * currentMagnitude * 0.005
        let zShake = Float(generatePerlinNoise(time: time + 200, frequency: 5.0)) * currentMagnitude * 0.008
        
        // Her nesneye kuvvet uygula
        for objectNode in detectedObjects {
            // Deprem büyüklüğüne dayalı hareket hesapla
            let shakeTransform = SCNMatrix4Translate(
                objectNode.transform,
                xShake * Float.random(in: 0.8...1.2),
                yShake * Float.random(in: 0.9...1.1),
                zShake * Float.random(in: 0.8...1.2)
            )
            
            // SCNTransaction ile animasyonlu hareket
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.1
            objectNode.transform = shakeTransform
            SCNTransaction.commit()
            
            // Bazı nesnelere rastgele dönme efekti ekle (gerçekçilik için)
            if Float.random(in: 0...1) < 0.2 * (currentMagnitude / 9.0) {
                let rotationAngle = Float.random(in: -0.05...0.05) * currentMagnitude * 0.01
                let rotationAxis = SCNVector3(x: Float.random(in: -1...1),
                                           y: Float.random(in: -1...1),
                                           z: Float.random(in: -1...1))
                
                objectNode.runAction(SCNAction.rotateBy(x: CGFloat(rotationAxis.x * rotationAngle),
                                                     y: CGFloat(rotationAxis.y * rotationAngle),
                                                     z: CGFloat(rotationAxis.z * rotationAngle),
                                                     duration: 0.1))
            }
        }
        
        // Kamera sallama efekti
        let cameraNode = arSceneView.pointOfView
        let originalTransform = cameraNode?.transform
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.05
        
        cameraNode?.transform = SCNMatrix4Translate(
            (originalTransform ?? SCNMatrix4Identity),
            xShake * 0.5,
            yShake * 0.5,
            zShake * 0.5
        )
        
        SCNTransaction.commit()
        
        // Kamerayı orijinal pozisyonuna geri getir
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.05
        cameraNode?.transform = originalTransform ?? SCNMatrix4Identity
        SCNTransaction.commit()
        
        // Deprem yoğunluğunu güncelle (viewModel'de)
        let intensity = Double(max(abs(xShake), abs(zShake)) * 10)
        viewModel.simulationIntensity = intensity
        
        // Haptic geri bildirim yoğunluğunu güncelle
        updateHapticIntensity(intensity: intensity)
    }
    
    private func stabilizeObjects() {
        // Tüm nesneleri orijinal pozisyonlarına ve rotasyonlarına getir
        for objectNode in detectedObjects {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            objectNode.transform = objectNode.transform // Şu anki durumu koru
            SCNTransaction.commit()
            
            // Tüm hareketleri durdur
            objectNode.removeAllActions()
        }
    }
    
    private func generatePerlinNoise(time: CFTimeInterval, frequency: Double) -> Double {
        return sin(time * frequency) * cos(time * frequency * 0.5) * 0.5
    }
    
    // MARK: - Object Creation Methods
    private func createTableSurfaceNode() -> SCNNode {
        let tableNode = SCNNode()
        
        // Masaüstü yüzeyi
        let tableGeometry = SCNBox(width: 1.2, height: 0.03, length: 0.8, chamferRadius: 0.02)
        tableGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        let tableTopNode = SCNNode(geometry: tableGeometry)
        tableTopNode.position = SCNVector3(x: 0, y: -0.2, z: -0.5)
        
        // Masa ayakları
        let legGeometry = SCNCylinder(radius: 0.03, height: 0.7)
        legGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 1.0)
        
        for (x, z) in [(0.5, 0.3), (0.5, -0.3), (-0.5, 0.3), (-0.5, -0.3)] {
            let legNode = SCNNode(geometry: legGeometry)
            legNode.position = SCNVector3(x: Float(x), y: -0.55, z: Float(z) - 0.5)
            tableNode.addChildNode(legNode)
        }
        
        tableNode.addChildNode(tableTopNode)
        
        return tableNode
    }
    
    private func createComputerNode() -> SCNNode {
        let computerNode = SCNNode()
        
        // Monitör
        let monitorScreenGeometry = SCNBox(width: 0.5, height: 0.3, length: 0.02, chamferRadius: 0.01)
        monitorScreenGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        let monitorScreen = SCNNode(geometry: monitorScreenGeometry)
        monitorScreen.position = SCNVector3(x: 0, y: 0, z: -0.5)
        
        // Monitör tabanı
        let monitorBaseGeometry = SCNBox(width: 0.2, height: 0.02, length: 0.1, chamferRadius: 0.01)
        monitorBaseGeometry.firstMaterial?.diffuse.contents = UIColor.darkGray
        let monitorBase = SCNNode(geometry: monitorBaseGeometry)
        monitorBase.position = SCNVector3(x: 0, y: -0.16, z: -0.45)
        
        // Klavye
        let keyboardGeometry = SCNBox(width: 0.4, height: 0.02, length: 0.15, chamferRadius: 0.01)
        keyboardGeometry.firstMaterial?.diffuse.contents = UIColor.lightGray
        let keyboard = SCNNode(geometry: keyboardGeometry)
        keyboard.position = SCNVector3(x: 0, y: -0.2, z: -0.3)
        
        // Fare
        let mouseGeometry = SCNBox(width: 0.06, height: 0.02, length: 0.1, chamferRadius: 0.01)
        mouseGeometry.firstMaterial?.diffuse.contents = UIColor.lightGray
        let mouse = SCNNode(geometry: mouseGeometry)
        mouse.position = SCNVector3(x: 0.25, y: -0.2, z: -0.3)
        
        computerNode.addChildNode(monitorScreen)
        computerNode.addChildNode(monitorBase)
        computerNode.addChildNode(keyboard)
        computerNode.addChildNode(mouse)
        
        return computerNode
    }
    
    private func createCoffeeMugNode() -> SCNNode {
        let mugNode = SCNNode()
        
        // Bardak
        let cupGeometry = SCNCylinder(radius: 0.04, height: 0.1)
        cupGeometry.firstMaterial?.diffuse.contents = UIColor.white
        let cup = SCNNode(geometry: cupGeometry)
        cup.position = SCNVector3(x: 0.3, y: -0.15, z: -0.4)
        
        // Kulp
        let handleGeometry = SCNTorus(ringRadius: 0.03, pipeRadius: 0.01)
        handleGeometry.firstMaterial?.diffuse.contents = UIColor.white
        let handle = SCNNode(geometry: handleGeometry)
        handle.position = SCNVector3(x: 0.33, y: -0.15, z: -0.4)
        handle.eulerAngles = SCNVector3(0, Float.pi/2, 0)
        
        mugNode.addChildNode(cup)
        mugNode.addChildNode(handle)
        
        return mugNode
    }
    
    private func createBookNode() -> SCNNode {
        let bookNode = SCNNode()
        
        // Kitap gövdesi
        let bookGeometry = SCNBox(width: 0.2, height: 0.03, length: 0.15, chamferRadius: 0.005)
        bookGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0)
        let book = SCNNode(geometry: bookGeometry)
        book.position = SCNVector3(x: -0.3, y: -0.18, z: -0.4)
        
        bookNode.addChildNode(book)
        
        return bookNode
    }
    
    private func createPenNode() -> SCNNode {
        let penNode = SCNNode()
        
        // Kalem
        let penGeometry = SCNCylinder(radius: 0.01, height: 0.15)
        penGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        let pen = SCNNode(geometry: penGeometry)
        pen.position = SCNVector3(x: -0.2, y: -0.19, z: -0.3)
        pen.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        
        penNode.addChildNode(pen)
        
        return penNode
    }
    
    // MARK: - UI Updates
    @objc private func magnitudeChanged(_ slider: UISlider) {
        currentMagnitude = slider.value
        magnitudeLabel.text = String(format: "Deprem Büyüklüğü: %.1f", currentMagnitude)
        
        // Büyüklüğe göre etiket rengini değiştir
        if currentMagnitude >= 7.0 {
            magnitudeLabel.textColor = .systemRed
        } else if currentMagnitude >= 5.0 {
            magnitudeLabel.textColor = .systemOrange
        } else {
            magnitudeLabel.textColor = .systemBlue
        }
    }
    
    private func updateIntensityLabel(intensity: Double) {
        // Deprem yoğunluğu göstergesini güncelle
        intensityLabel.text = String(format: "Şiddet: %.2f", intensity)
        
        // Yoğunluğa göre etiket rengini değiştir
        if intensity > 0.7 {
            intensityLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        } else if intensity > 0.4 {
            intensityLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.8)
        } else {
            intensityLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        }
    }
    
    // MARK: - Haptic Feedback
    private func startHapticFeedback() {
        // İlk haptic geri bildirim
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func updateHapticIntensity(intensity: Double) {
        // Deprem yoğunluğuna göre farklı haptic feedback
        if intensity > 0.7 {
            let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
            heavyFeedback.impactOccurred()
        } else if intensity > 0.4 {
            let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
            mediumFeedback.impactOccurred()
        } else if intensity > 0.2 {
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            lightFeedback.impactOccurred()
        }
    }
    
    // MARK: - Helper Methods
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
        
        view.addSubview(toastLabel)
        
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toastLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
    
    @objc private func showInfo() {
        let alertController = UIAlertController(
            title: "Gerçek Nesne Simülatörü",
            message: "Bu özellik, etrafınızdaki gerçek nesnelerin bir deprem sırasında nasıl etkilenebileceğini gösterir.\n\n1. 'Nesneleri Tanımla' butonuna basın ve kamerayı etrafınızda gezdirin.\n2. Deprem büyüklüğünü ayarlayın.\n3. Simülasyonu başlatın ve nesnelerin nasıl hareket ettiğini izleyin.",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Anladım", style: .default))
        present(alertController, animated: true)
    }
}

// MARK: - ARSCNViewDelegate
extension ARRealObjectSimulationViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // ARKit ile sürekli güncelleme
        // Burada her karede gerçekleşecek işlemler yapılabilir
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // AR oturumu hatası
        let errorMessage: String
        
        switch ARError.Code(rawValue: (error as NSError).code) {
        case .cameraUnauthorized:
            errorMessage = "Kamera erişimi reddedildi"
        case .worldTrackingFailed:
            errorMessage = "Dünya takibi başarısız oldu"
        default:
            errorMessage = "Beklenmeyen bir hata oluştu: \(error.localizedDescription)"
        }
        
        showARError(message: errorMessage)
    }
    
    private func showARError(message: String) {
        let alertController = UIAlertController(
            title: "AR Hatası",
            message: message,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alertController, animated: true)
    }
}
