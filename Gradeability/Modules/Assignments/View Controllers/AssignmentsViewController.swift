//
//  AssignmentsViewController.swift
//  Gradeability
//
//  Created by Ignacio Paradisi on 5/30/20.
//  Copyright © 2020 Ignacio Paradisi. All rights reserved.
//

import UIKit

class AssignmentsViewController: GradablesViewController {
    
    // MARK: Properties
    /// View model for the view
    private let viewModel: AssignmentsViewModel
    /// View for showing in case there's no assignments
    private var emptyView: EmptyGradablesView?
    
    // MARK: Initializers
    init(viewModel: AssignmentsViewModel) {
        self.viewModel = viewModel
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(GradesCardCollectionViewCell.self)
    }
    
    override func createDataSource() -> UICollectionViewDiffableDataSource<Sections, AnyHashable> {
        return UICollectionViewDiffableDataSource<Sections, AnyHashable>(collectionView: collectionView) { collectionView, indexPath, gradable in
            guard let section = Sections(rawValue: indexPath.section) else { return nil }
            switch section {
            case .gradables:
                guard let gradable = gradable as? GradableCellViewModel else { return nil }
                let cell = collectionView.dequeueReusableCell(for: indexPath) as TermCollectionViewCell
                let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
                cell.configure(with: gradable)
                cell.addInteraction(contextMenuInteraction)
                return cell
            case .grade:
                let cell = collectionView.dequeueReusableCell(for: indexPath) as GradesCardCollectionViewCell
                guard let viewModel = self.viewModel.gradeCardViewModelForRow(at: indexPath) else { return nil }
                cell.configure(with: viewModel)
                return cell
            }
        }
    }
    
    override func createSnapshot() -> NSDiffableDataSourceSnapshot<Sections, AnyHashable> {
        var snapshot = NSDiffableDataSourceSnapshot<Sections, AnyHashable>()
        snapshot.appendSections(Sections.allCases)
        snapshot.appendItems(viewModel.gradables, toSection: .gradables)
        return snapshot
    }
    
    /// Setup all View Model's closures to update the UI.
    override func setupViewModel() {
        viewModel.dataDidChange = { [weak self] in
            if self?.viewModel.numberOfRows(in: 1) == 0 {
                self?.showEmptyView()
            }
            #if !targetEnvironment(macCatalyst)
            self?.title = self?.viewModel.title
            #endif
            self?.reloadData()
            self?.collectionView.reloadData()
        }
    }
    
    /// Show view for creating an assignment in case there's no one created yet.
    private func showEmptyView() {
        emptyView = EmptyGradablesView(imageName: "doc.circle.fill",
                                       description: AssignmentString.emptyAssignments.localized,
                                       buttonTitle: AssignmentString.createAssignment.localized)
        emptyView?.delegate = self
        view.addSubview(emptyView!)
        emptyView?.anchor.edgesToSuperview().activate()
    }
    
    /// Handle navigation button for creating a new assignment
    /// - Parameter sender: Tap gesture
    override func didTapAddButton(_ sender: UIBarButtonItem?) {
        let createAssignmentViewController = CreateAssignmentViewController()
        createAssignmentViewController.isModalInPresentation = true
        let viewController = UINavigationController(rootViewController: createAssignmentViewController)
        present(viewController, animated: true)
    }
    
    #if targetEnvironment(macCatalyst)
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.defaultItemIdentifiers = [.newAssignment]
        let button = NSButtonTouchBarItem(identifier: .newAssignment, title: "New Assignment", image: UIImage(systemName: "plus")!, target: self, action: nil)
        touchBar.templateItems = [button]
        return touchBar
    }
    #endif
    
}

//// MARK: - UITableViewDataSource
//extension AssignmentsViewController {
//
//    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        <#code#>
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let section = Sections(rawValue: indexPath.section) else { return UITableViewCell() }
//        switch section {
//        case .grade:
//            let cell = tableView.dequeueReusableCell(for: indexPath) as GradesCardTableViewCell
//            guard let viewModel = self.viewModel.gradeCardViewModelForRow(at: indexPath) else { return UITableViewCell() }
//            cell.configure(with: viewModel)
//            return cell
//        case .gradables:
//            let cellViewModel = viewModel.gradableViewModelForRow(at: indexPath)
//            let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
//            let cell = tableView.dequeueReusableCell(for: indexPath) as GradableTableViewCell
//            cell.configure(with: cellViewModel)
//            cell.addInteraction(contextMenuInteraction)
//            return cell
//        }
//    }
//
//}

// MARK: - EmptyGradablesViewDelegate
extension AssignmentsViewController: EmptyGradablesViewDelegate {
    
    /// Handle create button tap when there's no assignment created
    func didTapButton() {
        viewModel.createAssignment()
        viewModel.fetch()
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.emptyView?.alpha = 0
        }, completion: { [weak self] _ in
            self?.emptyView?.removeFromSuperview()
            self?.emptyView = nil
        })
    }
    
}

// MARK: - UIContextMenuInteractionDelegate
extension AssignmentsViewController: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let locationInCollection = interaction.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: locationInCollection) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            return self?.viewModel.createContextualMenuForRow(at: indexPath)
        }
    }

}
