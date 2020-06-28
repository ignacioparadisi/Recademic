//
//  SubjectsViewModel.swift
//  Gradeability
//
//  Created by Ignacio Paradisi on 5/28/20.
//  Copyright © 2020 Ignacio Paradisi. All rights reserved.
//

import UIKit

class SubjectsViewModel: GradableViewModelRepresentable {

    private typealias Sections = SubjectsViewController.Sections
    
    // MARK: Private Properties
    /// Parent Term of the Subjects
    private var term: Term?
    /// Subjects to be displayed.
    private var subjects: [Subject] = []
    var gradables: [GradableCellViewModel] = []
    
    // MARK: Internal Properties
    var isMasterController: Bool = true
    /// Closure called when `subjects` changes so the UI can be updated.
    var dataDidChange: (() -> Void)?
    var didDeleteTerm: (() -> Void)?
    var numberOfSections: Int {
        return Sections.allCases.count
    }
    /// Term's name to be displayed as the `UIViewController` title.
    var title: String {
        return term?.name ?? "Subjects"
    }
    /// Title for the gradables section
    var sectionTitle: String {
        return "Subjects"
    }
    var termsViewModel: TermsViewModel {
        let viewModel = TermsViewModel()
        viewModel.delegate = self
        return viewModel
    }
    var canDeleteTerm: Bool {
        return !(term?.isCurrent ?? true)
    }
    var gradeCardViewModel: GradesCardCollectionViewCellViewModel? {
        guard let term = term else { return nil }
        let gradeCardViewModel = GradeCardViewModel(gradable: term, type: "Grade", message: "You are doing great!")
        return GradesCardCollectionViewCellViewModel(gradeCardViewModel: gradeCardViewModel)
    }
    
    // MARK: Initializers
    init(term: Term? = nil) {
        self.term = term
    }
    
    func setTerm(_ term: Term?) {
        self.term = term
        fetch()
    }
    
    // MARK: Functions
    /// Fetches the Subjects.
    func fetch() {
        guard let term = term else { return }
        SubjectCoreDataManager.shared.fetch(for: term) { [weak self] result in
            switch result {
            case .success(let subjects):
                self?.subjects = subjects
                self?.gradables = subjects.map { GradableCellViewModel(subject: $0) }
                self?.dataDidChange?()
            case .failure:
                break
            }
        }
    }
    
    func numberOfRows(in section: Int) -> Int {
        guard let section = Sections(rawValue: section) else { return 0 }
        switch section {
        case .grade:
            return 1
        case .gradables:
            return subjects.count
        }
    }
    
    /// Title for the gradables section
    func title(for section: Int) -> String? {
        guard let section = Sections(rawValue: section) else { return nil }
        switch section {
        case .grade:
            return nil
        case .gradables:
            return "Subjects"
        }
    }
    
    /// Gets the View Model for the `UITableViewCell` at the specified `IndexPath`.
    /// - Parameter indexPath: IndexPath where the View Model belongs.
    /// - Returns: The View Model for the specified `IndexPath`.
    func gradableViewModelForRow(at indexPath: IndexPath) -> GradableCellViewModelRepresentable {
        let subject = subjects[indexPath.row]
        return GradableCellViewModel(subject: subject)
    }
    
    /// Gets the View Model for the `UIViewController` to be displayed next when the user selects a `UITableViewCell`.
    /// - Parameter indexPath: IndexPath for the cell selected.
    func nextViewModelForRow(at indexPath: IndexPath) -> GradableViewModelRepresentable?  {
        let subject = subjects[indexPath.row]
        let viewModel = AssignmentsViewModel(subject: subject)
        return viewModel
        
    }
    
    func createContextualMenuForRow(at indexPath: IndexPath) -> UIMenu? {
        let subject = subjects[indexPath.row]
        var rootChildren: [UIMenuElement] = []
        let editAction = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")) { _ in
            
        }
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            CoreDataManager.shared.delete(subject)
            self.fetch()
        }
        rootChildren.append(editAction)
        rootChildren.append(deleteAction)
        
        let menu = UIMenu(title: "", children: rootChildren)
        return menu
    }
    
    func createSubject() {
        SubjectCoreDataManager.shared.create(term: term!, name: "Materia", maxGrade: 20, minGrade: 10, teacherName: "Carlitos Perez")
    }
    
    func deleteItem(at indexPath: IndexPath) {
        let subject = subjects[indexPath.row]
        CoreDataManager.shared.delete(subject)
        subjects.remove(at: indexPath.row)
    }
    
    func deleteTerm() {
        guard let term = term, !term.isCurrent else { return }
        CoreDataManager.shared.delete(term)
        didDeleteTerm?()
    }
    
}

// MARK: - TermsViewModelDelegate
extension SubjectsViewModel: TermsViewModelDelegate {
    func didChangeCurrentTerm(_ term: Term) {
        self.term = term
        fetch()
    }
}
