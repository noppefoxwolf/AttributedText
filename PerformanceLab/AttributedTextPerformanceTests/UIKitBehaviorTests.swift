import Observation
import SwiftUI
import UIKit
import XCTest

final class UIKitBehaviorTests: XCTestCase {
    @MainActor
    func testUpdatingVisiblePostUpdatesExistingViewAndCoordinator() async throws {
        let timeline = BehaviorTimeline(reuse: .replaceConfiguration)
        let window = attach(timeline)
        defer { window.isHidden = true }

        let indexPath = IndexPath(item: 0, section: 0)
        let initial = try await waitFor("First post to render") {
            timeline.renderedPost(at: indexPath)
        }
        XCTAssertEqual(initial.renderedText, "Post 0")
        let cell = try XCTUnwrap(timeline.collectionView.cellForItem(at: indexPath))

        timeline.posts[0].post.title = "Edited post 0"

        let updated = try await waitFor("Edited post to render") {
            timeline.renderedPost(at: indexPath).flatMap {
                $0.renderedText == "Edited post 0" ? $0 : nil
            }
        }
        XCTAssertTrue(timeline.collectionView.cellForItem(at: indexPath) === cell)
        XCTAssertTrue(initial.view === updated.view)
        XCTAssertEqual(initial.coordinatorID, updated.coordinatorID)
        XCTAssertGreaterThan(updated.updateCount, initial.updateCount)
    }

    @MainActor
    func testAssigningAnotherPostAfterClearingConfigurationCreatesNewViewAndCoordinator() async throws {
        let observation = try await observeReassignment(reuse: .clearConfiguration)
        XCTAssertFalse(observation.previous.view === observation.current.view)
        XCTAssertNotEqual(observation.previous.coordinatorID, observation.current.coordinatorID)
        XCTAssertEqual(observation.current.renderedText, observation.expectedText)
    }

    @MainActor
    func testSwappingPostValueWhileVisibleUpdatesExistingViewAndCoordinator() async throws {
        let timeline = BehaviorTimeline(reuse: .updateModel)
        let window = attach(timeline)
        defer { window.isHidden = true }

        let indexPath = IndexPath(item: 0, section: 0)
        let initial = try await waitFor("First post to render") {
            timeline.renderedPost(at: indexPath)
        }
        let cell = try XCTUnwrap(timeline.collectionView.cellForItem(at: indexPath) as? BehaviorCell)
        let contentView = cell.contentView
        let replacement = timeline.posts[1]
        cell.display(replacement, reuse: .updateModel)

        let updated = try await waitFor("Replacement post to render") {
            timeline.renderedPost(at: indexPath).flatMap {
                $0.renderedText == replacement.post.title ? $0 : nil
            }
        }
        XCTAssertTrue(timeline.collectionView.cellForItem(at: indexPath) === cell)
        XCTAssertTrue(cell.contentView === contentView)
        XCTAssertTrue(initial.view === updated.view)
        XCTAssertEqual(initial.coordinatorID, updated.coordinatorID)
        XCTAssertGreaterThan(updated.updateCount, initial.updateCount)
    }

    @MainActor
    func testObservingPostValueSwapDuringCellReuse() async throws {
        let observation = try await observeReassignment(reuse: .updateModel)
        XCTAssertTrue(observation.retainedContentView)
        record(observation, name: "Post value swap during cell reuse")
    }

    @MainActor
    func testObservingReassignmentWithConfigurationRetained() async throws {
        let observation = try await observeReassignment(reuse: .replaceConfiguration)
        record(observation, name: "Retained hosting configuration")
    }

    @MainActor
    private func record(_ observation: CellReassignment, name: String) {
        let attachment = XCTAttachment(string: """
            Previous text: \(observation.previous.renderedText)
            Expected text: \(observation.expectedText)
            Rendered text: \(observation.current.renderedText)
            Same UIView: \(observation.previous.view === observation.current.view)
            Same Coordinator: \(observation.previous.coordinatorID == observation.current.coordinatorID)
            Update calls before reassignment: \(observation.previous.updateCount)
            Update calls on current UIView: \(observation.current.updateCount)
            """)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func observeReassignment(
        reuse: CellReuse
    ) async throws -> CellReassignment {
        let timeline = BehaviorTimeline(reuse: reuse)
        let window = attach(timeline)
        defer { window.isHidden = true }

        _ = try await waitFor("First post to render") {
            timeline.renderedPost(at: IndexPath(item: 0, section: 0))
        }

        let collection = timeline.collectionView!
        for item in stride(from: 12, to: timeline.posts.count, by: 12) {
            collection.scrollToItem(at: IndexPath(item: item, section: 0), at: .top, animated: false)
            // Give SwiftUI time to deliver any deferred update before recording stale content.
            let clock = ContinuousClock()
            let deadline = clock.now + .milliseconds(300)
            repeat {
                collection.layoutIfNeeded()
                if let observation = timeline.visibleReassignment(),
                    observation.current.renderedText == observation.expectedText
                {
                    return observation
                }
                try await Task.sleep(for: .milliseconds(20))
            } while clock.now < deadline
            if let observation = timeline.visibleReassignment() {
                return observation
            }
        }
        return try XCTUnwrap(nil, "Expected a visible cell that completed prepareForReuse and was assigned another post")
    }

    @MainActor
    private func attach(_ timeline: BehaviorTimeline) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 360))
        window.rootViewController = timeline
        window.isHidden = false
        timeline.view.layoutIfNeeded()
        return window
    }

    @MainActor
    private func waitFor<Value>(_ description: String, value: () -> Value?) async throws -> Value {
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(2)
        repeat {
            if let result = value() { return result }
            try await Task.sleep(for: .milliseconds(20))
        } while clock.now < deadline
        return try XCTUnwrap(nil, description)
    }
}

private enum CellReuse {
    case replaceConfiguration
    case clearConfiguration
    case updateModel
}

private struct Post {
    let id: Int
    var title: String
}

@MainActor
@Observable
private final class HostedPostModel {
    var post: Post

    init(post: Post) {
        self.post = post
    }
}

private struct HostedPost: View {
    let model: HostedPostModel

    var body: some View {
        LifecycleLabel(title: model.post.title)
    }
}

private struct LifecycleLabel: UIViewRepresentable {
    let title: String

    final class Coordinator {
        let id = UUID()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ProbeLabel {
        ProbeLabel(coordinatorID: context.coordinator.id)
    }

    func updateUIView(_ view: ProbeLabel, context: Context) {
        view.text = title
        view.updateCount += 1
    }
}

private final class ProbeLabel: UILabel {
    let coordinatorID: UUID
    var updateCount = 0

    init(coordinatorID: UUID) {
        self.coordinatorID = coordinatorID
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("This label is created programmatically.")
    }
}

private struct RenderedPost {
    let view: ProbeLabel
    let renderedText: String
    let coordinatorID: UUID
    let updateCount: Int

    @MainActor
    init?(_ view: ProbeLabel?) {
        guard let view, let text = view.text else { return nil }
        self.view = view
        renderedText = text
        coordinatorID = view.coordinatorID
        updateCount = view.updateCount
    }
}

private final class BehaviorCell: UICollectionViewCell {
    var clearsConfigurationOnReuse = false
    var postIndex: Int?
    var previousPost: (index: Int, rendered: RenderedPost, contentView: UIView)?
    private var displayModel: HostedPostModel?

    func display(_ model: HostedPostModel, reuse: CellReuse) {
        clearsConfigurationOnReuse = reuse == .clearConfiguration
        postIndex = model.post.id

        if reuse == .updateModel {
            if let displayModel {
                displayModel.post = model.post
                return
            }
            let displayModel = HostedPostModel(post: model.post)
            self.displayModel = displayModel
            contentConfiguration = UIHostingConfiguration {
                HostedPost(model: displayModel)
            }
        } else {
            contentConfiguration = UIHostingConfiguration {
                HostedPost(model: model)
            }
        }
    }

    var renderedPost: RenderedPost? {
        RenderedPost(findLabel(in: contentView))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        previousPost = nil
        if let postIndex, let renderedPost {
            previousPost = (postIndex, renderedPost, contentView)
        }
        if clearsConfigurationOnReuse {
            contentConfiguration = nil
        }
    }

    private func findLabel(in view: UIView) -> ProbeLabel? {
        if let label = view as? ProbeLabel { return label }
        return view.subviews.lazy.compactMap { self.findLabel(in: $0) }.first
    }
}

private final class BehaviorTimeline: UICollectionViewController {
    let posts = (0..<72).map { HostedPostModel(post: Post(id: $0, title: "Post \($0)")) }
    let reuse: CellReuse

    init(reuse: CellReuse) {
        self.reuse = reuse
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 320, height: 60)
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("This controller is created programmatically.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(BehaviorCell.self, forCellWithReuseIdentifier: "Post")
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        posts.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Post", for: indexPath) as! BehaviorCell
        cell.display(posts[indexPath.item], reuse: reuse)
        return cell
    }

    func renderedPost(at indexPath: IndexPath) -> RenderedPost? {
        (collectionView.cellForItem(at: indexPath) as? BehaviorCell)?.renderedPost
    }

    func visibleReassignment() -> CellReassignment? {
        for indexPath in collectionView.indexPathsForVisibleItems.sorted() {
            guard let cell = collectionView.cellForItem(at: indexPath) as? BehaviorCell,
                let previous = cell.previousPost,
                previous.index != indexPath.item,
                let current = cell.renderedPost
            else { continue }
            return CellReassignment(
                previous: previous.rendered,
                current: current,
                expectedText: posts[indexPath.item].post.title,
                retainedContentView: previous.contentView === cell.contentView
            )
        }
        return nil
    }
}

private struct CellReassignment {
    let previous: RenderedPost
    let current: RenderedPost
    let expectedText: String
    let retainedContentView: Bool
}
