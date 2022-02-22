//
//  NCScan+CollectionView.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 22/02/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

@available(iOS 13.0, *)
extension NCScan: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return collectionView == collectionViewSource ? itemsSource.count : imagesDestination.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == collectionViewSource {

            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: "cell1", for: indexPath) as? NCScanCell)!

            let fileNamePath = CCUtility.getDirectoryScan() + "/" + itemsSource[indexPath.row]

            guard let data = try? Data(contentsOf: URL(fileURLWithPath: fileNamePath)) else {
                return cell
            }

            guard var image = UIImage(data: data) else {
                return cell
            }

            let imageWidthInPixels = image.size.width * image.scale
            let imageHeightInPixels = image.size.height * image.scale

            // 72 DPI
            if imageWidthInPixels > 595 || imageHeightInPixels > 842 {
                image = image.resizeImage(size: CGSize(width: 595, height: 842), isAspectRation: true) ?? image
            }

            cell.customImageView?.image = image
            cell.delete.action(for: .touchUpInside) { sender in

                let buttonPosition: CGPoint = (sender as? UIButton)!.convert(.zero, to: self.collectionViewSource)
                if let indexPath = self.collectionViewSource.indexPathForItem(at: buttonPosition) {

                    let fileNameAtPath = CCUtility.getDirectoryScan() + "/" + self.itemsSource[indexPath.row]
                    CCUtility.removeFile(atPath: fileNameAtPath)
                    self.itemsSource.remove(at: indexPath.row)

                    self.collectionViewSource.deleteItems(at: [indexPath])
                }
            }

            return cell

        } else {

            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as? NCScanCell)!
            cell.delegate = self
            cell.imageIndex = indexPath.row

            var image = imagesDestination[indexPath.row]

            let imageWidthInPixels = image.size.width * image.scale
            let imageHeightInPixels = image.size.height * image.scale

            // 72 DPI
            if imageWidthInPixels > 595 || imageHeightInPixels > 842 {
                image = image.resizeImage(size: CGSize(width: 595, height: 842), isAspectRation: true) ?? image
            }

            cell.customImageView?.image = self.filter(image: image)
            cell.customLabel.text = NSLocalizedString("_scan_document_pdf_page_", comment: "") + " " + "\(indexPath.row + 1)"

            return cell
        }
    }
}

@available(iOS 13.0, *)
extension NCScan: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

        if collectionView == collectionViewSource {
            let item = itemsSource[indexPath.row]
            let itemProvider = NSItemProvider(object: item as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)

            dragItem.localObject = item

            return [dragItem]

        } else {
            let item = imagesDestination[indexPath.row]
            let itemProvider = NSItemProvider(object: item as UIImage)
            let dragItem = UIDragItem(itemProvider: itemProvider)

            dragItem.localObject = item

            return [dragItem]
        }
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {

        if collectionView == collectionViewSource {
            let item = itemsSource[indexPath.row]
            let itemProvider = NSItemProvider(object: item as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)

            dragItem.localObject = item

            return [dragItem]

        } else {
            let item = imagesDestination[indexPath.row]
            let itemProvider = NSItemProvider(object: item as UIImage)
            let dragItem = UIDragItem(itemProvider: itemProvider)

            dragItem.localObject = item

            return [dragItem]
        }
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {

        let previewParameters = UIDragPreviewParameters()
        if collectionView == collectionViewSource {
            previewParameters.visiblePath = UIBezierPath(rect: CGRect(x: 20, y: 20, width: 100, height: 100))
        } else {
            previewParameters.visiblePath = UIBezierPath(rect: CGRect(x: 20, y: 20, width: 80, height: 80))
        }

        return previewParameters
    }
}

@available(iOS 13.0, *)
extension NCScan: UICollectionViewDropDelegate {

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {

        return true // session.canLoadObjects(ofClass: NSString.self)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {

        if collectionView == collectionViewSource {

            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .forbidden)
            }

        } else {

            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {

        let destinationIndexPath: IndexPath

        switch coordinator.proposal.operation {

        case .move:

            if let indexPath = coordinator.destinationIndexPath {

                destinationIndexPath = indexPath

            } else {

                // Get last index path of table view.
                let section = collectionView.numberOfSections - 1
                let row = collectionView.numberOfItems(inSection: section)

                destinationIndexPath = IndexPath(row: row, section: section)
            }
            self.reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)

        case .copy:

            // Get last index path of table view.
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)

            destinationIndexPath = IndexPath(row: row, section: section)
            self.copyItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)

        default:
            return
        }
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {

        collectionViewDestination.reloadData()

        // Save button
        if imagesDestination.isEmpty {
            save.isEnabled = false
        } else {
            save.isEnabled = true
        }
    }
}
