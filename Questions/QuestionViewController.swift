import UIKit
import GameplayKit // .shuffled()

class QuestionViewController: UIViewController {

	// MARK: Properties
	
	@IBOutlet var answersButtons: [UIButton]!
	@IBOutlet weak var remainingQuestionsLabel: UILabel!
	@IBOutlet weak var questionLabel: UILabel!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var endOfQuestions: UILabel!
	@IBOutlet weak var pauseButton: UIButton!
	@IBOutlet weak var pauseView: UIView!
	@IBOutlet weak var goBack: UIButton!
	@IBOutlet weak var muteMusic: UIButton!
	@IBOutlet weak var mainMenu: UIButton!

	let darkThemeEnabled = Settings.sharedInstance.darkThemeEnabled
	var blurViewPos = Int()
	var correctAnswers = Int32()
	var incorrectAnswers = Int32()
	var correctAnswer = Int()
	var currentSet = Int()
	var set: NSArray = []
	var quiz: NSEnumerator?
	var paused = true
	
	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()
		
		if #available(iOS 10.0, *) {
			set = (Quiz.set[currentSet] as! NSArray).shuffled() as NSArray
		}
		else {
			set = (Quiz.set[currentSet] as! [AnyObject]).shuffled() as NSArray
		}
		
		quiz = set.objectEnumerator()
		
		pauseView.isHidden = true
		endOfQuestions.isHidden = true
		statusLabel.alpha = 0.0
		
		// Saves the position where the blurView will be
		for i in 0..<view.subviews.count where (view.subviews[i] == pauseView) {
			blurViewPos = i - 1
		}

		let title = MainViewController.bgMusic?.isPlaying == true ? "Pause music" : "Play music"
		muteMusic.setTitle(title.localized, for: UIControlState())
		
		endOfQuestions.text = "End of questions".localized
		goBack.setTitle("Go back".localized, for: UIControlState())
		mainMenu.setTitle("Main menu".localized, for: UIControlState())
		pauseButton.setTitle("Pause".localized, for: UIControlState())
		
		// Theme settings

		let currentThemeColor = darkThemeEnabled ? UIColor.white : UIColor.black

		remainingQuestionsLabel.textColor = currentThemeColor
		questionLabel.textColor = currentThemeColor
		endOfQuestions.textColor = currentThemeColor
		view.backgroundColor = darkThemeEnabled ? UIColor.darkGray : UIColor.white
		pauseButton.setTitleColor(darkThemeEnabled ? UIColor.orange : UIColor.defaultTintColor, for: UIControlState())
		answersButtons.forEach { $0.backgroundColor = darkThemeEnabled ? UIColor.orange : UIColor.defaultTintColor }
		pauseView.backgroundColor = darkThemeEnabled ? UIColor.darkYellow : UIColor.myYellow
		pauseView.subviews.forEach { ($0 as! UIButton).setTitleColor(darkThemeEnabled ? UIColor.darkGray : UIColor.black, for: UIControlState()) }
		
		pickQuestion()
	}
	
	// MARK: UIViewController
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return darkThemeEnabled ? UIStatusBarStyle.lightContent : UIStatusBarStyle.default
	}

	override var shouldAutorotate: Bool {
		return pauseView.isHidden
	}

	// MARK: IBActions
	
	@IBAction func answer1Action() { verify(answer: 0) }
	@IBAction func answer2Action() { verify(answer: 1) }
	@IBAction func answer3Action() { verify(answer: 2) }
	@IBAction func answer4Action() { verify(answer: 3) }

	@IBAction func pauseMenu() {

		let title = paused ? "Continue" : "Pause"
		pauseButton.setTitle(title.localized, for: UIControlState())

		// BLUR BACKGROUND for pause menu
		/* Note: if this you want to remove the view and block the buttons you have to change the property .isEnabled to false of each button */

		if paused {
			let blurEffect = darkThemeEnabled ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
			let blurView = UIVisualEffectView(effect: blurEffect)
			blurView.frame = UIScreen.main.bounds
			view.insertSubview(blurView, at: blurViewPos)
		}
		else {
			view.subviews[blurViewPos].removeFromSuperview()
		}
		
		paused = paused ? false : true
		pauseView.isHidden = paused
	}
	
	@IBAction func muteMusicAction() {
		
		if let bgMusic = MainViewController.bgMusic {
			
			if bgMusic.isPlaying {
				bgMusic.pause()
				muteMusic.setTitle("Play music".localized, for: UIControlState())
			}
			else {
				bgMusic.play()
				muteMusic.setTitle("Pause music".localized, for: UIControlState())
			}
			
			Settings.sharedInstance.musicEnabled = bgMusic.isPlaying
		}
	}
	
	// MARK: Convenience
	
	func pickQuestion() {
		
		if let quiz = quiz?.nextObject() as? NSDictionary {
			
			correctAnswer = (quiz["answer"] as! Int)
			questionLabel.text = (quiz["question"] as! String).localized
			
			for i in 0..<answersButtons.count {
				answersButtons[i].setTitle((quiz["answers"] as! [String])[i].localized, for: UIControlState())
			}

			remainingQuestionsLabel.text = "\(set.index(of: quiz) + 1)/\(set.count)"
		}
		else {
			if !Settings.sharedInstance.completedSets[currentSet] {
				Settings.sharedInstance.correctAnswers += correctAnswers
				Settings.sharedInstance.incorrectAnswers += incorrectAnswers
			}
			
			Settings.sharedInstance.completedSets[currentSet] = true
			endOfQuestions.isHidden = false
			answersButtons.forEach { $0.isEnabled = false }
		}
	}

	func verify(answer: Int) {
		
		pausePreviousSounds()
		
		statusLabel.alpha = 1.0
		
		if answer == correctAnswer {
			statusLabel.textColor = darkThemeEnabled ? UIColor.lightGreen : UIColor.green
			statusLabel.text = "Correct!".localized
			MainViewController.correct?.play()
		}
		else {
			statusLabel.textColor = darkThemeEnabled ? UIColor.lightRed : UIColor.red
			statusLabel.text = "Incorrect".localized
			MainViewController.incorrect?.play()
		}
	
		if !Settings.sharedInstance.completedSets[currentSet] {
			(answer == correctAnswer) ? (correctAnswers += 1) : (incorrectAnswers += 1)
		}
		
		// Fade out animation for statusLabel
		UIView.animate(withDuration: 1.5) { self.statusLabel.alpha = 0.0 }
		
		pickQuestion()
	}
	
	func pausePreviousSounds() {
		
		if let incorrectSound = MainViewController.incorrect , incorrectSound.isPlaying {
			incorrectSound.pause()
			incorrectSound.currentTime = 0
		}
		
		if let correctSound = MainViewController.correct , correctSound.isPlaying {
			correctSound.pause()
			correctSound.currentTime = 0
		}
	}
}
