//
//  NavigationControllerRouterTest.swift
//  QuizAppTests
//
//  Created by Ramzy on 27/05/2021.
//

import Foundation
import XCTest
import QuizEngine
@testable import QuizApp


class NavigationControllerRouterTest: XCTestCase {
    let singleAnswerQuestion = Question.singleAnswer("Question 1")
    let multipleAnswerQuestion = Question.multipleAnswer("Question 2")
    
    let navigationController = NonAnimatedNavigationController()
    let factory = ViewControllerFactoryStub()
    lazy var sut: NavigationControllerRouter = {
        return NavigationControllerRouter(self.navigationController,factory: self.factory)
    }()
    

    func test_routeToQuestion_showsQuestionController() {
        let viewController = UIViewController()
        let secondViewController = UIViewController()
        factory.stub(question: singleAnswerQuestion, with: viewController)
        factory.stub(question:multipleAnswerQuestion, with: secondViewController)
        
        sut.routeTo(question: singleAnswerQuestion, answerCallback: { _ in})
        sut.routeTo(question:multipleAnswerQuestion, answerCallback: { _ in})

        XCTAssertEqual(navigationController.viewControllers.count,2)
        XCTAssertEqual(navigationController.viewControllers.first,viewController)
        XCTAssertEqual(navigationController.viewControllers.last,secondViewController)
    }
    
    func test_routeToQuestion_singleAnswer_answerCallback_progressesToNextQuestion() {
        var callbackWasFired = false
        sut.routeTo(question: singleAnswerQuestion, answerCallback: { _ in callbackWasFired = true})
        factory.answerCallback[singleAnswerQuestion]!(["Anything"])
        
        XCTAssertTrue(callbackWasFired)
     
    }
    
    func test_routeToQuestion_singleAnswer_doesNotConfigureViewControllerWithSubmitButton() {
        let viewController = UIViewController()
        factory.stub(question: singleAnswerQuestion, with: viewController)
        
        sut.routeTo(question:singleAnswerQuestion, answerCallback: { _ in})

        
        XCTAssertNil(viewController.navigationItem.rightBarButtonItem)
    }
    
    func test_routeToQuestion_multipleAnswer_answerCallback_doesNotProgressesToNextQuestion() {
        var callbackWasFired = false
        sut.routeTo(question:multipleAnswerQuestion, answerCallback: { _ in callbackWasFired = true})
        factory.answerCallback[multipleAnswerQuestion]!(["Anything"])
        
        XCTAssertFalse(callbackWasFired)
     
    }
    
    func test_routeToQuestion_multipleAnswer_configureViewControllerWithSubmitButton() {
        let viewController = UIViewController()
        factory.stub(question: multipleAnswerQuestion, with: viewController)
        
        sut.routeTo(question: multipleAnswerQuestion, answerCallback: { _ in})

        
        XCTAssertNotNil(viewController.navigationItem.rightBarButtonItem)
    }
    
    func test_routeToQuestion_multipleAnswerSubmitButton_isDisabledWhenZeroAnswersSelected() {
        let viewController = UIViewController()
        factory.stub(question: multipleAnswerQuestion, with: viewController)
        
        sut.routeTo(question: multipleAnswerQuestion, answerCallback: { _ in})
        XCTAssertFalse(viewController.navigationItem.rightBarButtonItem!.isEnabled)
        
        factory.answerCallback[multipleAnswerQuestion]!(["Answer 1"])
        XCTAssertTrue(viewController.navigationItem.rightBarButtonItem!.isEnabled)
        
        factory.answerCallback[multipleAnswerQuestion]!([])
        XCTAssertFalse(viewController.navigationItem.rightBarButtonItem!.isEnabled)
    }
    
    func test_routeToQuestion_multipleAnswerSubmitButton_progressesToNextQuestion() {
        let viewController = UIViewController()
        factory.stub(question: multipleAnswerQuestion, with: viewController)
        
        var callbackWasFired = false
        sut.routeTo(question: multipleAnswerQuestion, answerCallback: { _ in callbackWasFired = true})
        
        factory.answerCallback[multipleAnswerQuestion]!(["Answer 1"])
        
        viewController.navigationItem.rightBarButtonItem?.simulateTap()
        
        XCTAssertTrue(callbackWasFired)
    }
    
    
    func test_routeToResult_showsResultController() {
        let viewController = UIViewController()
        let result = Result.make(answers: [singleAnswerQuestion: ["Answer 1"]], score: 10)
        
        let secondViewController = UIViewController()
        let secondResult = Result.make(answers: [singleAnswerQuestion: ["Answer 2"]], score: 20)

        factory.stub(result: result, with: viewController)
        factory.stub(result: secondResult, with: secondViewController)
        
        sut.routeTo(result: result)
        sut.routeTo(result: secondResult)
      

        XCTAssertEqual(navigationController.viewControllers.count,2)
        XCTAssertEqual(navigationController.viewControllers.first,viewController)
        XCTAssertEqual(navigationController.viewControllers.last,secondViewController)

    }
    
    // MARK: - Helpers
    
    class NonAnimatedNavigationController: UINavigationController {
        override func pushViewController(_ viewController: UIViewController, animated: Bool) {
            super.pushViewController(viewController, animated: false)
        }
    }
    
    class ViewControllerFactoryStub: ViewControllerFactory {
        private var stubbedQuestions = [Question<String>: UIViewController]()
        private var stubbedResults = [Result<Question<String>,[String]>:UIViewController]()
        var answerCallback = [Question<String>: ([String]) -> Void]()
        
        func stub(question: Question<String>, with viewController: UIViewController) {
            stubbedQuestions[question] = viewController
        }
        
        func stub(result: Result<Question<String>,[String]>, with viewController: UIViewController) {
            stubbedResults[result] = viewController
        }
        
        func questionViewController(for question: Question<String>, answerCallback: @escaping ([String]) -> Void) -> UIViewController {
            self.answerCallback[question] = answerCallback
            return stubbedQuestions[question] ?? UIViewController()
        }
        
        func resultsViewController(for result: Result<Question<String>,[String]>) -> UIViewController {
            return stubbedResults[result] ?? UIViewController()
        }
        
    }
}

private extension UIBarButtonItem {
    func simulateTap() {
     target!.performSelector(onMainThread: action! , with: nil, waitUntilDone:true)
    }
}
